class Poltergeist.Browser
  constructor: (width, height) ->
    @width      = width || 1024
    @height     = height || 768
    @pages      = []
    @js_errors  = true
    @_debug     = false
    @_counter   = 0
    @_page_settings = null

    @processed_modal_messages = []
    @confirm_processes = []
    @prompt_responses = []

    this.resetPage()

  resetPage: ->
    [@_counter, @pages] = [0, []]

    if @page?
      unless @page.closed
        @page.clearLocalStorage() if @page.frameUrl() != 'about:blank'
        @page.close()
      phantom.clearCookies()

    @page = @currentPage = new Poltergeist.WebPage(null, @_page_settings)
    @page.setViewportSize(width: @width, height: @height)
    @page.handle = "#{@_counter++}"
    @pages.push(@page)

    @processed_modal_messages = []
    @confirm_processes = []
    @prompt_responses = []

    @setupPageHandlers(@page)

    return

  setupPageHandlers: (page) ->
    page.native().onAlert = (msg) =>
      @setModalMessage msg
      return

    page.native().onConfirm = (msg) =>
      process = @confirm_processes.pop()
      process = true if process == undefined
      @setModalMessage msg
      return process

    page.native().onPrompt = (msg, defaultVal) =>
      response = @prompt_responses.pop()
      response = defaultVal if (response == undefined || response == false)

      @setModalMessage msg
      return response

    page.onPageCreated = (newPage) =>
      _page = new Poltergeist.WebPage(newPage, @_page_settings)
      _page.handle = "#{@_counter++}"
      _page.urlBlacklist = page.urlBlacklist
      _page.urlWhitelist = page.urlWhitelist
      _page.setViewportSize(page.viewportSize())
      _page.setUserAgent(page.getUserAgent())
      _page.setCustomHeaders(page.getPermanentCustomHeaders())
      @setupPageHandlers(_page)
      @pages.push(_page)

    return

  getPageByHandle: (handle) ->
    @pages.filter((p) -> !p.closed && p.handle == handle)[0]

  runCommand: (command) ->
    @current_command = command
    @currentPage.state = 'default'
    this[command.name].apply(this, command.args)

  debug: (message) ->
    console.log "poltergeist [#{new Date().getTime()}] #{message}" if @_debug

  setModalMessage: (msg) ->
    @processed_modal_messages.push(msg)
    return

  add_extension: (extension) ->
    if @currentPage.injectExtension extension
      @current_command.sendResponse 'success'
    else
      @current_command.sendError(new Poltergeist.BrowserError("Unable to load extension: #{extension}"))

  node: (page_id, id) ->
    if @currentPage.id == page_id
      @currentPage.get(id)
    else
      throw new Poltergeist.ObsoleteNode

  visit: (url, max_wait=0) ->
    @currentPage.state = 'loading'
    #reset modal processing state when changing page
    @processed_modal_messages = []
    @confirm_processes = []
    @prompt_responses = []

    # Prevent firing `page.onInitialized` event twice. Calling currentUrl
    # method before page is actually opened fires this event for the first time.
    # The second time will be in the right place after `page.open`
    prevUrl = if @currentPage.source? then @currentPage.currentUrl() else 'about:blank'

    @currentPage.open(url)

    if /#/.test(url) && prevUrl.split('#')[0] == url.split('#')[0]
      # Hash change occurred, so there will be no onLoadFinished
      @currentPage.state = 'default'
      @current_command.sendResponse(status: 'success')
    else
      command = @current_command
      loading_page = @currentPage
      @currentPage.waitState 'default', ->
        if @statusCode == null && @status == 'fail'
          command.sendError(new Poltergeist.StatusFailError(url))
        else
          command.sendResponse(status: @status)
      , max_wait, ->
        resources = @openResourceRequests()
        msg = if resources.length
          "Timed out with the following resources still waiting #{resources.join(',')}"
        else
          "Timed out with no open resource requests"
        command.sendError(new Poltergeist.StatusFailError(url,msg))
      return

  current_url: ->
    @current_command.sendResponse @currentPage.currentUrl()

  frame_url: ->
    @current_command.sendResponse @currentPage.frameUrl()

  status_code: ->
    @current_command.sendResponse @currentPage.statusCode

  body: ->
    @current_command.sendResponse @currentPage.content()

  source: ->
    @current_command.sendResponse @currentPage.source

  title: ->
    @current_command.sendResponse @currentPage.title()

  frame_title: ->
    @current_command.sendResponse @currentPage.frameTitle()

  find: (method, selector) ->
    @current_command.sendResponse(page_id: @currentPage.id, ids: @currentPage.find(method, selector))

  find_within: (page_id, id, method, selector) ->
    @current_command.sendResponse this.node(page_id, id).find(method, selector)

  all_text: (page_id, id) ->
    @current_command.sendResponse this.node(page_id, id).allText()

  visible_text: (page_id, id) ->
    @current_command.sendResponse this.node(page_id, id).visibleText()

  delete_text: (page_id, id) ->
    @current_command.sendResponse this.node(page_id, id).deleteText()

  property: (page_id, id, name) ->
    @current_command.sendResponse this.node(page_id, id).getProperty(name)

  attribute: (page_id, id, name) ->
    @current_command.sendResponse this.node(page_id, id).getAttribute(name)

  attributes: (page_id, id, name) ->
    @current_command.sendResponse this.node(page_id, id).getAttributes()

  parents: (page_id, id) ->
    @current_command.sendResponse this.node(page_id, id).parentIds()

  value: (page_id, id) ->
    @current_command.sendResponse this.node(page_id, id).value()

  set: (page_id, id, value) ->
    this.node(page_id, id).set(value)
    @current_command.sendResponse(true)

  # PhantomJS only allows us to reference the element by CSS selector, not XPath,
  # so we have to add an attribute to the element to identify it, then remove it
  # afterwards.
  select_file: (page_id, id, value) ->
    node = this.node(page_id, id)

    @currentPage.beforeUpload(node.id)
    @currentPage.uploadFile('[_poltergeist_selected]', value)
    @currentPage.afterUpload(node.id)
    if phantom.version.major == 2 && phantom.version.minor == 0
      # In phantomjs 2.0.x - uploadFile only fully works if executed within a user action
      # It does however setup the filenames to be uploaded, so if we then click on the
      # file input element the filenames will get set
      @click(page_id, id)
    else
      @current_command.sendResponse(true)

  select: (page_id, id, value) ->
    @current_command.sendResponse this.node(page_id, id).select(value)

  tag_name: (page_id, id) ->
    @current_command.sendResponse this.node(page_id, id).tagName()

  visible: (page_id, id) ->
    @current_command.sendResponse this.node(page_id, id).isVisible()

  disabled: (page_id, id) ->
    @current_command.sendResponse this.node(page_id, id).isDisabled()

  path: (page_id, id) ->
    @current_command.sendResponse this.node(page_id, id).path()

  evaluate: (script, args...) ->
    for arg in args when @_isElementArgument(arg)
      throw new Poltergeist.ObsoleteNode if arg["ELEMENT"]["page_id"] != @currentPage.id
    @current_command.sendResponse @currentPage.evaluate("function() { return #{script} }", args...)

  evaluate_async: (script, max_wait, args...) ->
    for arg in args when @_isElementArgument(arg)
      throw new Poltergeist.ObsoleteNode if arg["ELEMENT"]["page_id"] != @currentPage.id
    command = @current_command
    cb = (result)=>
      command.sendResponse(result)
    @currentPage.evaluate_async("function() { #{script} }", cb, args...)
    setTimeout(=>
      command.sendError(new Poltergeist.ScriptTimeoutError)
    , max_wait*1000)


  execute: (script, args...) ->
    for arg in args when @_isElementArgument(arg)
      throw new Poltergeist.ObsoleteNode if arg["ELEMENT"]["page_id"] != @currentPage.id
    @currentPage.execute("function() { #{script} }", args...)
    @current_command.sendResponse(true)

  frameUrlFor: (frame_name) ->
    @currentPage.frameUrlFor(frame_name)

  pushFrame: (command, name, timeout) ->
    if Array.isArray(name)
      frame = this.node(name...)
      name = frame.getAttribute('name') || frame.getAttribute('id')
      unless name
        frame.setAttribute('name', "_random_name_#{new Date().getTime()}")
        name = frame.getAttribute('name')

    frame_url = @frameUrlFor(name)
    if frame_url in @currentPage.blockedUrls()
      command.sendResponse(true)
    else if @currentPage.pushFrame(name)
      # if frame_url && (frame_url != 'about:blank') && (@currentPage.currentUrl() == 'about:blank')
      if frame_url && (frame_url != 'about:blank') && (@currentPage.frameUrl() == 'about:blank')
        @currentPage.state = 'awaiting_frame_load'
        @currentPage.waitState 'default', ->
          command.sendResponse(true)
      else
        command.sendResponse(true)
    else
      if new Date().getTime() < timeout
        setTimeout((=> @pushFrame(command, name, timeout)), 50)
      else
        command.sendError(new Poltergeist.FrameNotFound(name))

  push_frame: (name, timeout = (new Date().getTime()) + 2000) ->
    @pushFrame(@current_command, name, timeout)

  pop_frame: (pop_all = false)->
    @current_command.sendResponse(@currentPage.popFrame(pop_all))

  window_handles: ->
    handles = @pages.filter((p) -> !p.closed).map((p) -> p.handle)
    @current_command.sendResponse(handles)

  window_handle: (name = null) ->
    handle = if name
      page = @pages.filter((p) -> !p.closed && p.windowName() == name)[0]
      if page then page.handle else null
    else
      @currentPage.handle

    @current_command.sendResponse(handle)

  switch_to_window: (handle) ->
    command = @current_command
    new_page = @getPageByHandle(handle)
    if new_page
      if new_page != @currentPage
        new_page.waitState 'default', =>
          @currentPage = new_page
          command.sendResponse(true)
      else
        command.sendResponse(true)
    else
      throw new Poltergeist.NoSuchWindowError

  open_new_window: ->
    this.execute 'window.open()'
    @current_command.sendResponse(true)

  close_window: (handle) ->
    page = @getPageByHandle(handle)
    if page
      page.close()
      @current_command.sendResponse(true)
    else
      @current_command.sendResponse(false)

  mouse_event: (page_id, id, name, keys=[], offset={}) ->
    # Get the node before changing state, in case there is an exception
    node = this.node(page_id, id)
    # If the event triggers onNavigationRequested, we will transition to the 'loading'
    # state and wait for onLoadFinished before sending a response.
    @currentPage.state = 'mouse_event'

    last_mouse_event = node.mouseEvent(name, keys, offset)
    event_page = @currentPage
    command = @current_command

    setTimeout ->
      # If the state is still the same then navigation event won't happen
      if event_page.state == 'mouse_event'
        event_page.state = 'default'
        command.sendResponse(position: last_mouse_event)
      else
        event_page.waitState 'default', ->
          command.sendResponse(position: last_mouse_event)
    , 5

  click: (page_id, id, keys, offset) ->
    this.mouse_event page_id, id, 'click', keys, offset

  right_click: (page_id, id, keys, offset) ->
    this.mouse_event page_id, id, 'rightclick', keys, offset

  double_click: (page_id, id, keys, offset) ->
    this.mouse_event page_id, id, 'doubleclick', keys, offset

  hover: (page_id, id) ->
    this.mouse_event page_id, id, 'mousemove'

  click_coordinates: (x, y) ->
    @currentPage.sendEvent('click', x, y)
    @current_command.sendResponse(click: { x: x, y: y })

  drag: (page_id, id, other_id) ->
    this.node(page_id, id).dragTo this.node(page_id, other_id)
    @current_command.sendResponse(true)

  drag_by: (page_id, id, x, y) ->
    this.node(page_id, id).dragBy(x, y)
    @current_command.sendResponse(true)

  trigger: (page_id, id, event) ->
    this.node(page_id, id).trigger(event)
    @current_command.sendResponse(event)

  equals: (page_id, id, other_id) ->
    @current_command.sendResponse this.node(page_id, id).isEqual(this.node(page_id, other_id))

  reset: ->
    this.resetPage()
    @current_command.sendResponse(true)

  scroll_to: (left, top) ->
    @currentPage.setScrollPosition(left: left, top: top)
    @current_command.sendResponse(true)

  send_keys: (page_id, id, keys) ->
    target = this.node(page_id, id)

    # Programmatically generated focus doesn't work for `sendKeys`.
    # That's why we need something more realistic like user behavior.
    if !target.containsSelection()
      target.mouseEvent('click')

    @_send_keys_with_modifiers(keys)
    @current_command.sendResponse(true)

  _send_keys_with_modifiers: (keys, current_modifier_code = 0) ->
    for sequence in keys
      if sequence.key?
        if !(key=@currentPage.keyCode(sequence.key))
          @current_command.sendError(new Poltergeist.KeyError("Unknown key: #{sequence.key}"))
          return
      else if sequence.keys?
        key=sequence.keys
      else
        key=sequence

      if sequence.modifier?
        modifier_keys = @currentPage.keyModifierKeys(sequence.modifier)
        modifier_code = @currentPage.keyModifierCode(sequence.modifier) | current_modifier_code
        @currentPage.sendEvent('keydown', modifier_key) for modifier_key in modifier_keys
        @_send_keys_with_modifiers([].concat(key), modifier_code)
        @currentPage.sendEvent('keyup', modifier_key) for modifier_key in modifier_keys
      else
        @currentPage.sendEvent('keypress', key, null, null, current_modifier_code)
    return true

  render_base64: (format, { full = false, selector = null } = {})->
    window_scroll_position = @currentPage.native().evaluate("function(){ return [window.pageXOffset, window.pageYOffset] }")
    dimensions = this.set_clip_rect(full, selector)
    encoded_image = @currentPage.renderBase64(format)
    @currentPage.setScrollPosition(left: dimensions.left, top: dimensions.top)
    @currentPage.native().evaluate("window.scrollTo", window_scroll_position...)

    @current_command.sendResponse(encoded_image)

  render: (path, { full = false, selector = null, format = null, quality = null } = {} ) ->
    window_scroll_position = @currentPage.native().evaluate("function(){ return [window.pageXOffset, window.pageYOffset] }")
    dimensions = this.set_clip_rect(full, selector)
    options = {}
    options["format"] = format if format?
    options["quality"] = quality if quality?
    @currentPage.setScrollPosition(left: 0, top: 0)
    @currentPage.render(path, options)
    @currentPage.setScrollPosition(left: dimensions.left, top: dimensions.top)
    @currentPage.native().evaluate("window.scrollTo", window_scroll_position...)

    @current_command.sendResponse(true)

  set_clip_rect: (full, selector) ->
    dimensions = @currentPage.validatedDimensions()
    [document, viewport] = [dimensions.document, dimensions.viewport]

    rect = if full
      left: 0, top: 0, width: document.width, height: document.height
    else
      if selector?
        @currentPage.elementBounds(selector)
      else
        left: 0, top: 0, width: viewport.width, height: viewport.height

    @currentPage.setClipRect(rect)
    dimensions

  set_paper_size: (size) ->
    @currentPage.setPaperSize(size)
    @current_command.sendResponse(true)

  set_zoom_factor: (zoom_factor) ->
    @currentPage.setZoomFactor(zoom_factor)
    @current_command.sendResponse(true)

  resize: (width, height) ->
    @currentPage.setViewportSize(width: width, height: height)
    @current_command.sendResponse(true)

  network_traffic: (type) ->
    @current_command.sendResponse(@currentPage.networkTraffic(type))

  clear_network_traffic: ->
    @currentPage.clearNetworkTraffic()
    @current_command.sendResponse(true)

  set_proxy: (ip, port, type, user, password) ->
    phantom.setProxy(ip, port, type, user, password)
    @current_command.sendResponse(true)

  get_headers: ->
    @current_command.sendResponse(@currentPage.getCustomHeaders())

  set_headers: (headers) ->
    this.add_headers(headers, false, false)

  add_headers: (headers, local = false, keepExisting = true) ->
    pages = if local then [@currentPage] else @pages
    pages.forEach (page) =>
      allHeaders = if keepExisting then page.getCustomHeaders() else {}
      for name, value of headers
        allHeaders[name] = value
      page.setUserAgent(allHeaders['User-Agent']) if allHeaders['User-Agent']
      page.setCustomHeaders(allHeaders)
    @current_command.sendResponse(true)

  add_header: (header, { permanent = true }) ->
    unless permanent == true
      @currentPage.addTempHeader(header)
      @currentPage.addTempHeaderToRemoveOnRedirect(header) if permanent == "no_redirect"
    this.add_headers(header, permanent != true)

  response_headers: ->
    @current_command.sendResponse(@currentPage.responseHeaders())

  cookies: ->
    @current_command.sendResponse(@currentPage.cookies())

  # We're using phantom.addCookie so that cookies can be set
  # before the first page load has taken place.
  set_cookie: (cookie) ->
    phantom.addCookie(cookie)
    @current_command.sendResponse(true)

  remove_cookie: (name) ->
    @currentPage.deleteCookie(name)
    @current_command.sendResponse(true)

  clear_cookies: () ->
    phantom.clearCookies()
    @current_command.sendResponse(true)

  cookies_enabled: (flag) ->
    phantom.cookiesEnabled = flag
    @current_command.sendResponse(true)

  set_http_auth: (user, password) ->
    @currentPage.setHttpAuth(user, password)
    @current_command.sendResponse(true)

  set_js_errors: (value) ->
    @js_errors = value
    @current_command.sendResponse(true)

  set_debug: (value) ->
    @_debug = value
    @current_command.sendResponse(true)

  set_page_settings: (settings)->
    @_page_settings = settings
    @page.setSettings(@_page_settings)
    @current_command.sendResponse(true)

  exit: ->
    phantom.exit()

  noop: ->
    # NOOOOOOP!

  # This command is purely for testing error handling
  browser_error: ->
    throw new Error('zomg')

  go_back: ->
    if @currentPage.canGoBack
      @currentPage.state = 'wait_for_loading'
      @currentPage.goBack()
      @_waitForHistoryChange()
    else
      @current_command.sendResponse(false)

  go_forward: ->
    if @currentPage.canGoForward
      @currentPage.state = 'wait_for_loading'
      @currentPage.goForward()
      @_waitForHistoryChange()
    else
      @current_command.sendResponse(false)

  refresh: ->
    @currentPage.state = 'wait_for_loading'
    @currentPage.reload()
    @_waitForHistoryChange()

  set_url_whitelist: (wildcards...)->
    @currentPage.urlWhitelist = (@_wildcardToRegexp(wc) for wc in wildcards)
    @current_command.sendResponse(true)

  set_url_blacklist: (wildcards...)->
    @currentPage.urlBlacklist = (@_wildcardToRegexp(wc) for wc in wildcards)
    @current_command.sendResponse(true)

  set_confirm_process: (process) ->
    @confirm_processes.push process
    @current_command.sendResponse(true)

  set_prompt_response: (response) ->
    @prompt_responses.push response
    @current_command.sendResponse(true)

  modal_message: ->
    @current_command.sendResponse(@processed_modal_messages.shift())

  clear_memory_cache: ->
    @currentPage.clearMemoryCache()
    @current_command.sendResponse(true)

  _waitForHistoryChange: ->
    command = @current_command
    @currentPage.waitState ['loading','default'], (cur_state) ->
      if cur_state == 'loading'
        # loading has started, wait for completion
        @waitState 'default', ->
          command.sendResponse(true)
      else
        # page has loaded
        command.sendResponse(true)
    , 0.5, ->
      # if haven't moved to loading/default in time assume history API state change
      @state = 'default'
      command.sendResponse(true)

  _wildcardToRegexp: (wildcard)->
    wildcard = wildcard.replace(/[\-\[\]\/\{\}\(\)\+\.\\\^\$\|]/g, "\\$&")
    wildcard = wildcard.replace(/\*/g, ".*")
    wildcard = wildcard.replace(/\?/g, ".")
    new RegExp(wildcard, "i")

  _isElementArgument: (arg)->
    typeof(arg) == "object" and typeof(arg['ELEMENT']) == "object"
