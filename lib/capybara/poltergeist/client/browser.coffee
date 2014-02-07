class Poltergeist.Browser
  constructor: (@owner, width, height) ->
    @width      = width || 1024
    @height     = height || 768
    @state      = "default"
    @page_stack = []
    @page_id    = 0
    @js_errors  = true
    @_debug     = false

    @resetPage()

  resetPage: ->
    if @page?
      @page.release()
      phantom.clearCookies()

    @page = new Poltergeist.WebPage
    @page.setViewportSize { @width, @height }

    @page.onLoadStarted = =>
      @setState "loading" if @state is "mouse_event"

    @page.onNavigationRequested = (url, navigation) =>
      @setState "loading" if @state is "mouse_event" and navigation is "FormSubmitted"

    @page.onLoadFinished = (status) =>
      if @state is "loading"
        @sendResponse { status, position: @last_mouse_event }
        @setState "default"
      else if @state is "awaiting_frame_load"
        @sendResponse true
        @setState "default"

    @page.onInitialized = => @page_id += 1

    @page.onPageCreated = (sub_page) =>
      if @state is "awaiting_sub_page"
        name       = @page_name
        @page_name = null

        @setState "default"

        # At this point subpage isn't fully initialized, so we can't check
        # its name. Instead, we just schedule another attempt to push the
        # window.
        setTimeout (=> @push_window name), 0

  runCommand: (name, args) ->
    @setState "default"
    @[name](args...)

  debug: (message) -> console.log "poltergeist [#{new Date().getTime()}] #{message}" if @_debug

  setState: (state) ->
    return if @state is state
    @debug "state #{@state} -> #{state}"
    @state = state

  sendResponse: (response) ->
    errors = @page.errors()
    @page.clearErrors()

    if errors.length and @js_errors
      @owner.sendError new Poltergeist.JavascriptError(errors)
    else
      @owner.sendResponse response

  add_extension: (extension) ->
    @page.injectExtension extension
    @sendResponse 'success'

  node: (page_id, id) ->
    if page_id == @page_id
      @page.get(id)
    else
      throw new Poltergeist.ObsoleteNode

  visit: (url) ->
    @setState "loading"

    # Prevent firing `page.onInitialized` event twice. Calling currentUrl
    # method before page is actually opened fires this event for the first time.
    # The second time will be in the right place after `page.open`
    prev_url = if @page.source() is null then "about:blank" else @page.currentUrl()

    @page.open url

    if /#/.test(url) && prev_url.split("#")[0] == url.split("#")[0]
      # hashchange occurred, so there will be no onLoadFinished
      @setState "default"
      @sendResponse "success"

  current_url: -> @sendResponse @page.currentUrl()

  status_code: -> @sendResponse @page.statusCode()

  body: -> @sendResponse @page.content()

  source: -> @sendResponse @page.source()

  title: -> @sendResponse @page.title()

  find: (method, selector) -> @sendResponse { @page_id, ids: @page.find(method, selector) }

  find_within: (page_id, id, method, selector) -> @sendResponse @node(page_id, id).find(method, selector)

  all_text: (page_id, id) -> @sendResponse @node(page_id, id).allText()

  visible_text: (page_id, id) -> @sendResponse @node(page_id, id).visibleText()

  delete_text: (page_id, id) -> @sendResponse @node(page_id, id).deleteText()

  attribute: (page_id, id, name) -> @sendResponse @node(page_id, id).getAttribute(name)

  value: (page_id, id) -> @sendResponse @node(page_id, id).value()

  set: (page_id, id, value) ->
    @node(page_id, id).set value
    @sendResponse true

  # PhantomJS only allows us to reference the element by CSS selector, not XPath,
  # so we have to add an attribute to the element to identify it, then remove it
  # afterwards.
  select_file: (page_id, id, value) ->
    node = @node(page_id, id)

    @page.beforeUpload node.id
    @page.uploadFile '[_poltergeist_selected]', value
    @page.afterUpload node.id

    @sendResponse true

  select: (page_id, id, value) -> @sendResponse @node(page_id, id).select(value)

  tag_name: (page_id, id) -> @sendResponse @node(page_id, id).tagName()

  visible: (page_id, id) -> @sendResponse @node(page_id, id).isVisible()

  disabled: (page_id, id) -> @sendResponse @node(page_id, id).isDisabled()

  evaluate: (script) -> @sendResponse @page.evaluate("function() { return #{script} }")

  execute: (script) ->
    @page.execute "function() { #{script} }"
    @sendResponse true

  push_frame: (name, timeout = new Date().getTime() + 2000) ->
    if @page.pushFrame(name)
      if @page.currentUrl() is "about:blank"
        @setState "awaiting_frame_load"
      else
        @sendResponse true
    else
      if new Date().getTime() < timeout
        setTimeout (=> @push_frame name, timeout), 50
      else
        @owner.sendError new Poltergeist.FrameNotFound(name)

  pages: -> @sendResponse @page.pages()

  pop_frame: -> @sendResponse @page.popFrame()

  push_window: (name) ->
    sub_page = @page.getPage(name)

    if sub_page
      if sub_page.currentUrl() is "about:blank"
        sub_page.onLoadFinished = =>
          sub_page.onLoadFinished = null
          @push_window name
      else
        @page_stack.push @page
        @page = sub_page
        @page_id += 1
        @sendResponse true
    else
      @page_name = name
      @setState "awaiting_sub_page"

  pop_window: ->
    prev_page = @page_stack.pop()
    @page = prev_page if prev_page
    @sendResponse true

  mouse_event: (page_id, id, name) ->
    # Get the node before changing state, in case there is an exception
    node = @node(page_id, id)

    # If the event triggers onNavigationRequested, we will transition to the 'loading'
    # state and wait for onLoadFinished before sending a response.
    @setState "mouse_event"

    @last_mouse_event = node.mouseEvent(name)

    setTimeout =>
      if @state isnt "loading"
        @setState "default"
        @sendResponse @last_mouse_event
    , 5

  click: (page_id, id) -> @mouse_event page_id, id, "click"

  double_click: (page_id, id) -> @mouse_event page_id, id, "doubleclick"

  hover: (page_id, id) -> @mouse_event page_id, id, "mousemove"

  click_coordinates: (x, y) ->
    @page.sendEvent 'click', x, y
    @sendResponse click: { x, y }

  drag: (page_id, id, other_id) ->
    @node(page_id, id).dragTo @node(page_id, other_id)
    @sendResponse true

  trigger: (page_id, id, event) ->
    @node(page_id, id).trigger event
    @sendResponse event

  equals: (page_id, id, other_id) -> @sendResponse @node(page_id, id).isEqual(@node(page_id, other_id))

  reset: ->
    @resetPage()
    @sendResponse true

  scroll_to: (left, top) ->
    @page.setScrollPosition { left, top }
    @sendResponse true

  send_keys: (page_id, id, keys) ->
    # Programmatically generated focus doesn't work for `sendKeys`.
    # That's why we need something more realistic like user behavior.
    @node(page_id, id).mouseEvent 'click'
    for sequence in keys
      key = if sequence.key? then @page.native.event.key[sequence.key] else sequence
      @page.sendEvent "keypress", key
    @sendResponse true

  render_base64: (format, full, selector = null)->
    @set_clip_rect full, selector
    encoded_image = @page.renderBase64(format)
    @sendResponse encoded_image

  render: (path, full, selector = null) ->
    dimensions = @set_clip_rect full, selector
    @page.setScrollPosition left: 0, top: 0
    @page.render path
    @page.setScrollPosition left: dimensions.left, top: dimensions.top
    @sendResponse true

  set_clip_rect: (full, selector) ->
    dimensions = @page.validatedDimensions()
    [document, viewport] = [dimensions.document, dimensions.viewport]

    rect = if full
      left: 0, top: 0, width: document.width, height: document.height
    else
      if selector?
        @page.elementBounds(selector)
      else
        left: 0, top: 0, width: viewport.width, height: viewport.height

    @page.setClipRect rect
    dimensions

  set_paper_size: (size) ->
    @page.setPaperSize size
    @sendResponse true

  set_zoom_factor: (zoom_factor) ->
    @page.setZoomFactor zoom_factor
    @sendResponse true

  resize: (width, height) ->
    @page.setViewportSize { width, height }
    @sendResponse true

  network_traffic: ->
    @sendResponse @page.networkTraffic()

  clear_network_traffic: ->
    @page.clearNetworkTraffic()
    @sendResponse true

  get_headers: ->
    @sendResponse @page.getCustomHeaders()

  set_headers: (headers) ->
    # Workaround for https://code.google.com/p/phantomjs/issues/detail?id=745
    @page.setUserAgent headers['User-Agent'] if headers['User-Agent']
    @page.setCustomHeaders headers
    @sendResponse true

  add_headers: (headers) ->
    allHeaders = @page.getCustomHeaders()
    for name, value of headers
      allHeaders[name] = value
    @set_headers allHeaders

  add_header: (header, permanent) ->
    @page.addTempHeader header unless permanent
    @add_headers header

  response_headers: -> @sendResponse @page.responseHeaders()

  cookies: -> @sendResponse @page.cookies()

  # We're using phantom.addCookie so that cookies can be set
  # before the first page load has taken place.
  set_cookie: (cookie) ->
    phantom.addCookie cookie
    @sendResponse true

  remove_cookie: (name) ->
    @page.deleteCookie name
    @sendResponse true

  cookies_enabled: (flag) ->
    phantom.cookiesEnabled = flag
    @sendResponse true

  set_http_auth: (user, password) ->
    @page.setHttpAuth user, password
    @sendResponse true

  set_js_errors: (value) ->
    @js_errors = value
    @sendResponse true

  set_debug: (value) ->
    @_debug = value
    @sendResponse true

  exit: -> phantom.exit()

  noop: -> # NOOOOOOP!

  # This command is purely for testing error handling
  browser_error: -> throw new Error("zomg")

  go_back: ->
    @page.goBack() if @page.canGoBack
    @sendResponse true

  go_forward: ->
    @page.goForward() if @page.canGoForward
    @sendResponse true
