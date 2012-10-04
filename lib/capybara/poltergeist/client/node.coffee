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
    @page.sendEvent('keypress', value.toString())
    this.blur()
