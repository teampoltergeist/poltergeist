class Poltergeist.Browser
  constructor: (@owner, width, height) ->
    @width      = width || 1024
    @height     = height || 768
    @state      = "default"
    @pageStack  = []
    @pageId     = 0
    @jsErrors   = true
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
        @sendResponse { status, position: @lastMouseEvent }
        @setState "default"
      else if @state is "awaiting_frame_load"
        @sendResponse true
        @setState "default"

    @page.onInitialized = => @pageId += 1

    @page.onPageCreated = (subPage) =>
      if @state is "awaiting_sub_page"
        name       = @pageName
        @pageName = null

        @setState "default"

        # At this point subpage isn't fully initialized, so we can't check
        # its name. Instead, we just schedule another attempt to push the
        # window.
        setTimeout (=> @pushWindow name), 0

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

    if errors.length and @jsErrors
      @owner.sendError new Poltergeist.JavascriptError(errors)
    else
      @owner.sendResponse response

  addExtension: (extension) ->
    @page.injectExtension extension
    @sendResponse 'success'

  node: (pageId, id) ->
    if pageId == @pageId
      @page.get(id)
    else
      throw new Poltergeist.ObsoleteNode

  visit: (url) ->
    @setState "loading"

    # Prevent firing `page.onInitialized` event twice. Calling currentUrl
    # method before page is actually opened fires this event for the first time.
    # The second time will be in the right place after `page.open`
    prevUrl = if @page.source() is null then "about:blank" else @page.currentUrl()

    @page.open url

    if /#/.test(url) && prevUrl.split("#")[0] == url.split("#")[0]
      # hashchange occurred, so there will be no onLoadFinished
      @setState "default"
      @sendResponse "success"

  currentUrl: -> @sendResponse @page.currentUrl()

  statusCode: -> @sendResponse @page.statusCode()

  body: -> @sendResponse @page.content()

  source: -> @sendResponse @page.source()

  title: -> @sendResponse @page.title()

  find: (method, selector) -> @sendResponse { @pageId, ids: @page.find(method, selector) }

  findWithin: (pageId, id, method, selector) -> @sendResponse @node(pageId, id).find(method, selector)

  allText: (pageId, id) -> @sendResponse @node(pageId, id).allText()

  visibleText: (pageId, id) -> @sendResponse @node(pageId, id).visibleText()

  deleteText: (pageId, id) -> @sendResponse @node(pageId, id).deleteText()

  attribute: (pageId, id, name) -> @sendResponse @node(pageId, id).getAttribute(name)

  value: (pageId, id) -> @sendResponse @node(pageId, id).value()

  set: (pageId, id, value) ->
    @node(pageId, id).set value
    @sendResponse true

  # PhantomJS only allows us to reference the element by CSS selector, not XPath,
  # so we have to add an attribute to the element to identify it, then remove it
  # afterwards.
  selectFile: (pageId, id, value) ->
    node = @node(pageId, id)

    @page.beforeUpload node.id
    @page.uploadFile '[_poltergeist_selected]', value
    @page.afterUpload node.id

    @sendResponse true

  select: (pageId, id, value) -> @sendResponse @node(pageId, id).select(value)

  tagName: (pageId, id) -> @sendResponse @node(pageId, id).tagName()

  visible: (pageId, id) -> @sendResponse @node(pageId, id).isVisible()

  disabled: (pageId, id) -> @sendResponse @node(pageId, id).isDisabled()

  evaluate: (script) -> @sendResponse @page.evaluate("function() { return #{script} }")

  execute: (script) ->
    @page.execute "function() { #{script} }"
    @sendResponse true

  pushFrame: (name, timeout = new Date().getTime() + 2000) ->
    if @page.pushFrame(name)
      if @page.currentUrl() is "about:blank"
        @setState "awaiting_frame_load"
      else
        @sendResponse true
    else
      if new Date().getTime() < timeout
        setTimeout (=> @pushFrame name, timeout), 50
      else
        @owner.sendError new Poltergeist.FrameNotFound(name)

  pages: -> @sendResponse @page.pages()

  popFrame: -> @sendResponse @page.popFrame()

  pushWindow: (name) ->
    subPage = @page.getPage(name)

    if subPage
      if subPage.currentUrl() is "about:blank"
        subPage.onLoadFinished = =>
          subPage.onLoadFinished = null
          @pushWindow name
      else
        @pageStack.push @page
        @page = subPage
        @pageId += 1
        @sendResponse true
    else
      @pageName = name
      @setState "awaiting_sub_page"

  popWindow: ->
    prevPage = @pageStack.pop()
    @page = prevPage if prevPage
    @sendResponse true

  mouseEvent: (pageId, id, name) ->
    # Get the node before changing state, in case there is an exception
    node = @node(pageId, id)

    # If the event triggers onNavigationRequested, we will transition to the 'loading'
    # state and wait for onLoadFinished before sending a response.
    @setState "mouse_event"

    @lastMouseEvent = node.mouseEvent(name)

    setTimeout =>
      if @state isnt "loading"
        @setState "default"
        @sendResponse @lastMouseEvent
    , 5

  click: (pageId, id) -> @mouseEvent pageId, id, "click"

  doubleClick: (pageId, id) -> @mouseEvent pageId, id, "doubleclick"

  hover: (pageId, id) -> @mouseEvent pageId, id, "mousemove"

  clickCoordinates: (x, y) ->
    @page.sendEvent 'click', x, y
    @sendResponse click: { x, y }

  drag: (pageId, id, otherId) ->
    @node(pageId, id).dragTo @node(pageId, otherId)
    @sendResponse true

  trigger: (pageId, id, event) ->
    @node(pageId, id).trigger event
    @sendResponse event

  equals: (pageId, id, otherId) -> @sendResponse @node(pageId, id).isEqual(@node(pageId, otherId))

  reset: ->
    @resetPage()
    @sendResponse true

  scrollTo: (left, top) ->
    @page.setScrollPosition { left, top }
    @sendResponse true

  sendKeys: (pageId, id, keys) ->
    # Programmatically generated focus doesn't work for `sendKeys`.
    # That's why we need something more realistic like user behavior.
    @node(pageId, id).mouseEvent "click"
    for sequence in keys
      key = if sequence.key? then @page.native.event.key[sequence.key] else sequence
      @page.sendEvent "keypress", key
    @sendResponse true

  renderBase64: (format, full, selector = null)->
    @setClipRect full, selector
    encodedImage = @page.renderBase64(format)
    @sendResponse encodedImage

  render: (path, full, selector = null) ->
    dimensions = @setClipRect full, selector
    @page.setScrollPosition left: 0, top: 0
    @page.render path
    @page.setScrollPosition left: dimensions.left, top: dimensions.top
    @sendResponse true

  setClipRect: (full, selector) ->
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

  setPaperSize: (size) ->
    @page.setPaperSize size
    @sendResponse true

  setZoomFactor: (zoomFactor) ->
    @page.setZoomFactor zoomFactor
    @sendResponse true

  resize: (width, height) ->
    @page.setViewportSize { width, height }
    @sendResponse true

  networkTraffic: -> @sendResponse @page.networkTraffic()

  clearNetworkTraffic: ->
    @page.clearNetworkTraffic()
    @sendResponse true

  getHeaders: ->
    @sendResponse @page.getCustomHeaders()

  setHeaders: (headers) ->
    # Workaround for https://code.google.com/p/phantomjs/issues/detail?id=745
    @page.setUserAgent headers['User-Agent'] if headers['User-Agent']
    @page.setCustomHeaders headers
    @sendResponse true

  addHeaders: (headers) ->
    allHeaders = @page.getCustomHeaders()
    allHeaders[name] = value for name, value of headers
    @setHeaders allHeaders

  addHeader: (header, permanent) ->
    @page.addTempHeader header unless permanent
    @addHeaders header

  responseHeaders: -> @sendResponse @page.responseHeaders()

  cookies: -> @sendResponse @page.cookies()

  # We're using phantom.addCookie so that cookies can be set
  # before the first page load has taken place.
  setCookie: (cookie) ->
    phantom.addCookie cookie
    @sendResponse true

  removeCookie: (name) ->
    @page.deleteCookie name
    @sendResponse true

  cookiesEnabled: (flag) ->
    phantom.cookiesEnabled = flag
    @sendResponse true

  setHttpAuth: (user, password) ->
    @page.setHttpAuth user, password
    @sendResponse true

  setJsErrors: (value) ->
    @jsErrors = value
    @sendResponse true

  setDebug: (value) ->
    @_debug = value
    @sendResponse true

  exit: -> phantom.exit()

  noop: -> # NOOOOOOP!

  # This command is purely for testing error handling
  browserError: -> throw new Error("zomg")

  goBack: ->
    @page.goBack() if @page.canGoBack
    @sendResponse true

  goForward: ->
    @page.goForward() if @page.canGoForward
    @sendResponse true
