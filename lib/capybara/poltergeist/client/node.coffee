# Proxy object for forwarding method calls to the node object inside the page.

class Poltergeist.Node
  @DELEGATES = ['text', 'getAttribute', 'value', 'setAttribute', 'isObsolete',
                'removeAttribute', 'isMultiple', 'select', 'tagName', 'find',
                'isVisible', 'position', 'trigger', 'parentId', 'clickTest',
                'scrollIntoView', 'isDOMEqual', 'focusAndHighlight', 'blur']

  constructor: (@page, @id) ->

  parent: ->
    new Poltergeist.Node(@page, this.parentId())

  for name in @DELEGATES
    do (name) =>
      this.prototype[name] = (args...) ->
        @page.nodeCall(@id, name, args)

  clickPosition: ->
    viewport = @page.viewportSize()
    pos      = this.position()

    middle = (start, end, size) ->
      start + ((Math.min(end, size) - start) / 2)

    {
      x: middle(pos.left, pos.right,  viewport.width),
      y: middle(pos.top,  pos.bottom, viewport.height)
    }

  click: ->
    this.scrollIntoView()

    pos  = this.clickPosition()
    test = this.clickTest(pos.x, pos.y)

    if test.status == 'success'
      @page.mouseEvent('click', pos.x, pos.y)
      pos
    else
      throw new Poltergeist.ClickFailed(test.selector, pos)

  dragTo: (other) ->
    this.scrollIntoView()

    position      = this.clickPosition()
    otherPosition = other.clickPosition()

    @page.mouseEvent('mousedown', position.x,      position.y)
    @page.mouseEvent('mouseup',   otherPosition.x, otherPosition.y)

  isEqual: (other) ->
    @page == other.page && this.isDOMEqual(other.id)

  set: (value) ->
    this.focusAndHighlight()
    # Sending backspace to clear the input
    # keycode from: https://github.com/ariya/phantomjs/commit/cab2635e66d74b7e665c44400b8b20a8f225153a#L0R370
    @page.sendEvent('keypress', 16777219)
    @page.sendEvent('keypress', value.toString())
    this.blur()
