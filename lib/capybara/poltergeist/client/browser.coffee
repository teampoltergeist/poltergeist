class Poltergeist.Browser
  constructor: (@owner, width, height) ->
    @width   = width || 1024
    @height  = height || 768
    @state   = 'default'
    @page_id = 0

    this.resetPage()

  resetPage: ->
    @page.release() if @page?
    @page = new Poltergeist.WebPage(@width, @height)

    @page.onLoadStarted = =>
      @state = 'loading' if @state == 'clicked'

    @page.onLoadFinished = (status) =>
      if @state == 'loading'
        this.sendResponse(status)
        @state = 'default'

    @page.onInitialized = =>
      @page_id += 1

  sendResponse: (response) ->
    errors = @page.errors()

    if errors.length > 0
      @page.clearErrors()
      @owner.sendError(new Poltergeist.JavascriptError(errors))
    else
      @owner.sendResponse(response)

  getNode: (page_id, id, callback) ->
    if page_id == @page_id
      callback.call this, @page.get(id)
    else
      @owner.sendError(new Poltergeist.ObsoleteNode)

  nodeCall: (page_id, id, fn, args...) ->
    callback = args.pop()

    this.getNode(
      page_id, id,
      (node) ->
        result = node[fn](args...)

        if result instanceof Poltergeist.ObsoleteNode
          @owner.sendError(result)
        else
          callback.call(this, result, node)
    )

  visit: (url) ->
    @state = 'loading'
    @page.open(url)

  current_url: ->
    this.sendResponse @page.currentUrl()

  body: ->
    this.sendResponse @page.content()

  source: ->
    this.sendResponse @page.source()

  find: (selector) ->
    this.sendResponse(page_id: @page_id, ids: @page.find(selector))

  find_within: (page_id, id, selector) ->
    this.nodeCall(page_id, id, 'find', selector, this.sendResponse)

  text: (page_id, id) ->
    this.nodeCall(page_id, id, 'text', this.sendResponse)

  attribute: (page_id, id, name) ->
    this.nodeCall(page_id, id, 'getAttribute', name, this.sendResponse)

  value: (page_id, id) ->
    this.nodeCall(page_id, id, 'value', this.sendResponse)

  set: (page_id, id, value) ->
    this.nodeCall(page_id, id, 'set', value, -> this.sendResponse(true))

  # PhantomJS only allows us to reference the element by CSS selector, not XPath,
  # so we have to add an attribute to the element to identify it, then remove it
  # afterwards.
  #
  # PhantomJS does not support multiple-file inputs, so we have to blatently cheat
  # by temporarily changing it to a single-file input. This obviously could break
  # things in various ways, which is not ideal, but it works in the simplest case.
  select_file: (page_id, id, value) ->
    this.nodeCall(
      page_id, id, 'isMultiple',
      (multiple, node) ->
        node.removeAttribute('multiple') if multiple
        node.setAttribute('_poltergeist_selected', '')

        @page.uploadFile('[_poltergeist_selected]', value)

        node.removeAttribute('_poltergeist_selected')
        node.setAttribute('multiple', 'multiple') if multiple

        this.sendResponse(true)
    )

  select: (page_id, id, value) ->
    this.nodeCall(page_id, id, 'select', value, this.sendResponse)

  tag_name: (page_id, id) ->
    this.nodeCall(page_id, id, 'tagName', this.sendResponse)

  visible: (page_id, id) ->
    this.nodeCall(page_id, id, 'isVisible', this.sendResponse)

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

  click: (page_id, id) ->
    # We just check the node is not obsolete before proceeding. If it is,
    # the callback will not fire.
    this.nodeCall(
      page_id, id, 'isObsolete',
      (obsolete, node) ->
        # If the click event triggers onLoadStarted, we will transition to the 'loading'
        # state and wait for onLoadFinished before sending a response.
        @state = 'clicked'

        click = node.click()

        # Use a timeout in order to let the stack clear, so that the @page.onLoadStarted
        # callback can (possibly) fire, before we decide whether to send a response.
        setTimeout(
          =>
            if @state == 'clicked'
              @state = 'default'

              if click instanceof Poltergeist.ClickFailed
                @owner.sendError(click)
              else
                this.sendResponse(true)
          ,
          10
        )
    )

  drag: (page_id, id, other_id) ->
    this.nodeCall(
      page_id, id, 'isObsolete'
      (obsolete, node) ->
        node.dragTo(@page.get(other_id))
        this.sendResponse(true)
    )

  trigger: (page_id, id, event) ->
    this.nodeCall(page_id, id, 'trigger', event, -> this.sendResponse(event))

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

  networkTraffic: (filter) ->
    if filter
      matches = []
      for traffic in @page.networkTraffic()
        matches.push(traffic) if traffic.request.match(filter)
    else
      matches = @page.networkTraffic()

    this.sendResponse(matches)

  exit: ->
    phantom.exit()

  noop: ->
    # NOOOOOOP!
