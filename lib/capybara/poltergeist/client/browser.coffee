class Poltergeist.Browser
  constructor: (@owner, width, height) ->
    @width      = width || 1024
    @height     = height || 768
    @pages      = []
    @js_errors  = true
    @_debug     = false
    @_counter   = 0

    this.resetPage()

  resetPage: ->
    [@_counter, @pages] = [0, []]

    if @page?
      unless @page.closed
        @page.clearLocalStorage() if @page.currentUrl() != 'about:blank'
        @page.release()
      phantom.clearCookies()

    @page = @currentPage = new Poltergeist.WebPage
    @page.setViewportSize(width: @width, height: @height)
    @page.handle = "#{@_counter++}"
    @pages.push(@page)

    @page.onPageCreated = (newPage) =>
      page = new Poltergeist.WebPage(newPage)
      page.handle = "#{@_counter++}"
      @pages.push(page)

  getPageByHandle: (handle) ->
    @pages.filter((p) -> !p.closed && p.handle == handle)[0]

  runCommand: (name, args) ->
    @currentPage.state = 'default'
    this[name].apply(this, args)

  debug: (message) ->
    if @_debug
      console.log "poltergeist [#{new Date().getTime()}] #{message}"

  sendResponse: (response) ->
    errors = @currentPage.errors
    @currentPage.clearErrors()

    if errors.length > 0 && @js_errors
      @owner.sendError(new Poltergeist.JavascriptError(errors))
    else
      @owner.sendResponse(response)

  add_extension: (extension) ->
    @currentPage.injectExtension extension
    this.sendResponse 'success'

  node: (page_id, id) ->
    if @currentPage.id == page_id
      @currentPage.get(id)
    else
      throw new Poltergeist.ObsoleteNode

  visit: (url) ->
    @currentPage.state = 'loading'

    # Prevent firing `page.onInitialized` event twice. Calling currentUrl
    # method before page is actually opened fires this event for the first time.
    # The second time will be in the right place after `page.open`
    prevUrl = if @currentPage.source is null then 'about:blank' else @currentPage.currentUrl()

    @currentPage.open(url)

    if /#/.test(url) && prevUrl.split('#')[0] == url.split('#')[0]
      # Hash change occurred, so there will be no onLoadFinished
      @currentPage.state = 'default'
      this.sendResponse(status: 'success')
    else
      @currentPage.waitState 'default', =>
        if @currentPage.statusCode == null && @currentPage.status == 'fail'
          @owner.sendError(new Poltergeist.StatusFailError)
        else
          this.sendResponse(status: @currentPage.status)

  current_url: ->
    this.sendResponse @currentPage.currentUrl()

  status_code: ->
    this.sendResponse @currentPage.statusCode

  body: ->
    this.sendResponse @currentPage.content()

  source: ->
    this.sendResponse @currentPage.source

  title: ->
    this.sendResponse @currentPage.title()

  find: (method, selector) ->
    this.sendResponse(page_id: @currentPage.id, ids: @currentPage.find(method, selector))

  find_within: (page_id, id, method, selector) ->
    this.sendResponse this.node(page_id, id).find(method, selector)

  all_text: (page_id, id) ->
    this.sendResponse this.node(page_id, id).allText()

  visible_text: (page_id, id) ->
    this.sendResponse this.node(page_id, id).visibleText()

  delete_text: (page_id, id) ->
    this.sendResponse this.node(page_id, id).deleteText()

  attribute: (page_id, id, name) ->
    this.sendResponse this.node(page_id, id).getAttribute(name)

  attributes: (page_id, id, name) ->
    this.sendResponse this.node(page_id, id).getAttributes()

  parents: (page_id, id) ->
    this.sendResponse this.node(page_id, id).parentIds()

  value: (page_id, id) ->
    this.sendResponse this.node(page_id, id).value()

  set: (page_id, id, value) ->
    this.node(page_id, id).set(value)
    this.sendResponse(true)

  # PhantomJS only allows us to reference the element by CSS selector, not XPath,
  # so we have to add an attribute to the element to identify it, then remove it
  # afterwards.
  select_file: (page_id, id, value) ->
    node = this.node(page_id, id)

    @currentPage.beforeUpload(node.id)
    @currentPage.uploadFile('[_poltergeist_selected]', value)
    @currentPage.afterUpload(node.id)

    this.sendResponse(true)

  select: (page_id, id, value) ->
    this.sendResponse this.node(page_id, id).select(value)

  tag_name: (page_id, id) ->
    this.sendResponse this.node(page_id, id).tagName()

  visible: (page_id, id) ->
    this.sendResponse this.node(page_id, id).isVisible()

  disabled: (page_id, id) ->
    this.sendResponse this.node(page_id, id).isDisabled()

  evaluate: (script) ->
    this.sendResponse @currentPage.evaluate("function() { return #{script} }")

  execute: (script) ->
    @currentPage.execute("function() { #{script} }")
    this.sendResponse(true)

  frameUrl: (frame_name) ->
    @currentPage.frameUrl(frame_name)

  push_frame: (name, timeout = new Date().getTime() + 2000) ->
    if @frameUrl(name) in @currentPage.blockedUrls()
      this.sendResponse(true)
    else if @currentPage.pushFrame(name)
      if @currentPage.currentUrl() == 'about:blank'
        @currentPage.state = 'awaiting_frame_load'
        @currentPage.waitState 'default', =>
          this.sendResponse(true)
      else
        this.sendResponse(true)
    else
      if new Date().getTime() < timeout
        setTimeout((=> this.push_frame(name, timeout)), 50)
      else
        @owner.sendError(new Poltergeist.FrameNotFound(name))

  pop_frame: ->
    this.sendResponse(@currentPage.popFrame())

  window_handles: ->
    handles = @pages.filter((p) -> !p.closed).map((p) -> p.handle)
    this.sendResponse(handles)

  window_handle: (name = null) ->
    handle = if name
      page = @pages.filter((p) -> !p.closed && p.windowName() == name)[0]
      if page then page.handle else null
    else
      @currentPage.handle

    this.sendResponse(handle)

  switch_to_window: (handle) ->
    page = @getPageByHandle(handle)
    if page
      if page != @currentPage
        page.waitState 'default', =>
          @currentPage = page
          this.sendResponse(true)
      else
        this.sendResponse(true)
    else
      throw new Poltergeist.NoSuchWindowError

  open_new_window: ->
    this.execute 'window.open()'
    this.sendResponse(true)

  close_window: (handle) ->
    page = @getPageByHandle(handle)
    if page
      page.release()
      this.sendResponse(true)
    else
      this.sendResponse(false)

  mouse_event: (page_id, id, name) ->
    # Get the node before changing state, in case there is an exception
    node = this.node(page_id, id)

    # If the event triggers onNavigationRequested, we will transition to the 'loading'
    # state and wait for onLoadFinished before sending a response.
    @currentPage.state = 'mouse_event'

    @last_mouse_event = node.mouseEvent(name)

    setTimeout =>
      # If the state is still the same then navigation event won't happen
      if @currentPage.state == 'mouse_event'
        @currentPage.state = 'default'
        this.sendResponse(position: @last_mouse_event)
      else
        @currentPage.waitState 'default', =>
          this.sendResponse(position: @last_mouse_event)
    , 5

  click: (page_id, id) ->
    this.mouse_event page_id, id, 'click'

  right_click: (page_id, id) ->
    this.mouse_event page_id, id, 'rightclick'

  double_click: (page_id, id) ->
    this.mouse_event page_id, id, 'doubleclick'

  hover: (page_id, id) ->
    this.mouse_event page_id, id, 'mousemove'

  click_coordinates: (x, y) ->
    @currentPage.sendEvent('click', x, y)
    this.sendResponse(click: { x: x, y: y })

  drag: (page_id, id, other_id) ->
    this.node(page_id, id).dragTo this.node(page_id, other_id)
    this.sendResponse(true)

  trigger: (page_id, id, event) ->
    this.node(page_id, id).trigger(event)
    this.sendResponse(event)

  equals: (page_id, id, other_id) ->
    this.sendResponse this.node(page_id, id).isEqual(this.node(page_id, other_id))

  reset: ->
    this.resetPage()
    this.sendResponse(true)

  scroll_to: (left, top) ->
    @currentPage.setScrollPosition(left: left, top: top)
    this.sendResponse(true)

  send_keys: (page_id, id, keys) ->
    target = this.node(page_id, id)

    # Programmatically generated focus doesn't work for `sendKeys`.
    # That's why we need something more realistic like user behavior.
    if !target.containsSelection()
      target.mouseEvent('click')

    for sequence in keys
      key = if sequence.key? then @currentPage.keyCode(sequence.key) else sequence
      @currentPage.sendEvent('keypress', key)
    this.sendResponse(true)

  render_base64: (format, full, selector = null)->
    this.set_clip_rect(full, selector)
    encoded_image = @currentPage.renderBase64(format)
    this.sendResponse(encoded_image)

  render: (path, full, selector = null) ->
    dimensions = this.set_clip_rect(full, selector)
    @currentPage.setScrollPosition(left: 0, top: 0)
    @currentPage.render(path)
    @currentPage.setScrollPosition(left: dimensions.left, top: dimensions.top)
    this.sendResponse(true)

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
    this.sendResponse(true)

  set_zoom_factor: (zoom_factor) ->
    @currentPage.setZoomFactor(zoom_factor)
    this.sendResponse(true)

  resize: (width, height) ->
    @currentPage.setViewportSize(width: width, height: height)
    this.sendResponse(true)

  network_traffic: ->
    this.sendResponse(@currentPage.networkTraffic())

  clear_network_traffic: ->
    @currentPage.clearNetworkTraffic()
    this.sendResponse(true)

  get_headers: ->
    this.sendResponse(@currentPage.getCustomHeaders())

  set_headers: (headers) ->
    # Workaround for https://code.google.com/p/phantomjs/issues/detail?id=745
    @currentPage.setUserAgent(headers['User-Agent']) if headers['User-Agent']
    @currentPage.setCustomHeaders(headers)
    this.sendResponse(true)

  add_headers: (headers) ->
    allHeaders = @currentPage.getCustomHeaders()
    for name, value of headers
      allHeaders[name] = value
    this.set_headers(allHeaders)

  add_header: (header, permanent) ->
    @currentPage.addTempHeader(header) unless permanent
    this.add_headers(header)

  response_headers: ->
    this.sendResponse(@currentPage.responseHeaders())

  cookies: ->
    this.sendResponse(@currentPage.cookies())

  # We're using phantom.addCookie so that cookies can be set
  # before the first page load has taken place.
  set_cookie: (cookie) ->
    phantom.addCookie(cookie)
    this.sendResponse(true)

  remove_cookie: (name) ->
    @currentPage.deleteCookie(name)
    this.sendResponse(true)

  clear_cookies: () ->
    phantom.clearCookies()
    this.sendResponse(true)

  cookies_enabled: (flag) ->
    phantom.cookiesEnabled = flag
    this.sendResponse(true)

  set_http_auth: (user, password) ->
    @currentPage.setHttpAuth(user, password)
    this.sendResponse(true)

  set_js_errors: (value) ->
    @js_errors = value
    this.sendResponse(true)

  set_debug: (value) ->
    @_debug = value
    this.sendResponse(true)

  exit: ->
    phantom.exit()

  noop: ->
    # NOOOOOOP!

  # This command is purely for testing error handling
  browser_error: ->
    throw new Error('zomg')

  go_back: ->
    if @currentPage.canGoBack
      @currentPage.state = 'loading'
      @currentPage.goBack()
      @currentPage.waitState 'default', =>
        this.sendResponse(true)
    else
      this.sendResponse(false)

  go_forward: ->
    if @currentPage.canGoForward
      @currentPage.state = 'loading'
      @currentPage.goForward()
      @currentPage.waitState 'default', =>
        this.sendResponse(true)
    else
      this.sendResponse(false)

  set_url_blacklist: ->
    @currentPage.urlBlacklist = Array.prototype.slice.call(arguments)
    @sendResponse(true)
