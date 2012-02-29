class Poltergeist.Browser
  constructor: (@owner) ->
    @state = 'default'
    this.resetPage()

  resetPage: ->
    @page.release() if @page?

    @page = new Poltergeist.WebPage

    @page.onLoadStarted = =>
      @state = 'loading' if @state == 'clicked'

    @page.onLoadFinished = (status) =>
      if @state == 'loading'
        this.sendResponse(status)
        @state = 'default'

  sendResponse: (response) ->
    errors = @page.errors()

    if errors.length > 0
      @page.clearErrors()
      @owner.sendError(new Poltergeist.JavascriptError(errors))
    else
      @owner.sendResponse(response)

  visit: (url) ->
    @state = 'loading'
    @page.open(url)

  current_url: ->
    this.sendResponse @page.currentUrl()

  body: ->
    this.sendResponse @page.content()

  source: ->
    this.sendResponse @page.source()

  find: (selector, id) ->
    this.sendResponse @page.find(selector, id)

  text: (id) ->
    this.sendResponse @page.get(id).text()

  attribute: (id, name) ->
    this.sendResponse @page.get(id).getAttribute(name)

  value: (id) ->
    this.sendResponse @page.get(id).value()

  set: (id, value) ->
    @page.get(id).set(value)
    this.sendResponse(true)

  # PhantomJS only allows us to reference the element by CSS selector, not XPath,
  # so we have to add an attribute to the element to identify it, then remove it
  # afterwards.
  #
  # PhantomJS does not support multiple-file inputs, so we have to blatently cheat
  # by temporarily changing it to a single-file input. This obviously could break
  # things in various ways, which is not ideal, but it works in the simplest case.
  select_file: (id, value) ->
    element = @page.get(id)

    multiple = element.isMultiple()

    element.removeAttribute('multiple') if multiple
    element.setAttribute('_poltergeist_selected', '')

    @page.uploadFile('[_poltergeist_selected]', value)

    element.removeAttribute('_poltergeist_selected')
    element.setAttribute('multiple', 'multiple') if multiple

    this.sendResponse(true)

  select: (id, value) ->
    this.sendResponse @page.get(id).select(value)

  tag_name: (id) ->
    this.sendResponse @page.get(id).tagName()

  visible: (id) ->
    this.sendResponse @page.get(id).isVisible()

  evaluate: (script) ->
    this.sendResponse JSON.parse(@page.evaluate("function() { return JSON.stringify(#{script}) }"))

  execute: (script) ->
    @page.execute("function() { #{script} }")
    this.sendResponse(true)

  push_frame: (id) ->
    @page.pushFrame(id)
    this.sendResponse(true)

  pop_frame: ->
    @page.popFrame()
    this.sendResponse(true)

  click: (id) ->
    # If the click event triggers onLoadStarted, we will transition to the 'loading'
    # state and wait for onLoadFinished before sending a response.
    @state = 'clicked'

    @page.get(id).click()

    # Use a timeout in order to let the stack clear, so that the @page.onLoadStarted
    # callback can (possibly) fire, before we decide whether to send a response.
    setTimeout(
      =>
        if @state == 'clicked'
          @state = 'default'
          this.sendResponse(true)
      ,
      10
    )

  drag: (id, other_id) ->
    @page.get(id).dragTo(@page.get(other_id))
    this.sendResponse(true)

  trigger: (id, event) ->
    @page.get(id).trigger(event)
    this.sendResponse(event)

  reset: ->
    this.resetPage()
    this.sendResponse(true)

  render: (path, full) ->
    dimensions = @page.validatedDimensions()
    document   = dimensions.document
    viewport   = dimensions.viewport

    if full
      @page.setScrollPosition(left: 0, top: 0)
      @page.setClipRect(left: 0, top: 0, width: document.width, height: document.height)
      @page.render(path)
      @page.setScrollPosition(left: dimensions.left, top: dimensions.top)
    else
      @page.setClipRect(left: 0, top: 0, width: viewport.width, height: viewport.height)
      @page.render(path)

    this.sendResponse(true)

  resize: (width, height) ->
    @page.setViewportSize(width: width, height: height)
    this.sendResponse(true)

  exit: ->
    phantom.exit()

  noop: ->
    # NOOOOOOP!
