class Poltergeist.Browser
  constructor: (@owner) ->
    @awaiting_response = false
    this.resetPage()

  resetPage: ->
    @page.release() if @page?

    @page = new Poltergeist.WebPage
    @page.onLoadFinished = (status) =>
      if @awaiting_response
        @owner.sendResponse(status)
        @awaiting_response = false

  visit: (url) ->
    @awaiting_response = true
    @page.open(url)

  current_url: ->
    @owner.sendResponse @page.currentUrl()

  body: ->
    @owner.sendResponse @page.content()

  source: ->
    @owner.sendResponse @page.source()

  find: (selector, id) ->
    @owner.sendResponse @page.find(selector, id)

  text: (id) ->
    @owner.sendResponse @page.get(id).text()

  attribute: (id, name) ->
    @owner.sendResponse @page.get(id).getAttribute(name)

  value: (id) ->
    @owner.sendResponse @page.get(id).value()

  set: (id, value) ->
    @page.get(id).set(value)
    @owner.sendResponse(true)

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

    @owner.sendResponse(true)

  select: (id, value) ->
    @owner.sendResponse @page.get(id).select(value)

  tag_name: (id) ->
    @owner.sendResponse @page.get(id).tagName()

  visible: (id) ->
    @owner.sendResponse @page.get(id).isVisible()

  evaluate: (script) ->
    @owner.sendResponse @page.evaluate("function() { return #{script} }")

  execute: (script) ->
    @page.execute("function() { return #{script} }")
    @owner.sendResponse(true)

  push_frame: (id) ->
    @page.pushFrame(id)
    @owner.sendResponse(true)

  pop_frame: ->
    @page.popFrame()
    @owner.sendResponse(true)

  click: (id) ->
    # Detect if the click event triggers a page load. If it does, don't send
    # a response here, because the response will be sent once the page has loaded.
    @page.onLoadStarted = => @awaiting_response = true

    @page.get(id).click()

    # Use a timeout in order to let the stack clear, so that the @page.onLoadStarted
    # callback can (possibly) fire, before we decide whether to send a response.
    setTimeout(
      =>
        @page.onLoadStarted = null
        @owner.sendResponse(true) unless @awaiting_response
      ,
      0
    )

  drag: (id, other_id) ->
    @page.get(id).dragTo(@page.get(other_id))
    @owner.sendResponse(true)

  trigger: (id, event) ->
    @page.get(id).trigger(event)
    @owner.sendResponse(event)

  reset: ->
    this.resetPage()
    @owner.sendResponse(true)

  render: (path) ->
    @page.render(path)
    @owner.sendResponse(true)
