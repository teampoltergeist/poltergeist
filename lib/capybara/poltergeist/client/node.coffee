# Proxy object for forwarding method calls to the node object inside the page.

class Poltergeist.Node
  @DELEGATES = ['text', 'getAttribute', 'value', 'set', 'setAttribute', 'isObsolete',
                'removeAttribute', 'isMultiple', 'select', 'tagName', 'find',
                'isVisible', 'position', 'trigger', 'parentId', 'clickTest',
                'scrollIntoView', 'isDOMEqual']

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
      @page.sendEvent('click', pos.x, pos.y)
    else
      throw new Poltergeist.ClickFailed(test.selector, pos)

  dragTo: (other) ->
    this.scrollIntoView()

    position      = this.clickPosition()
    otherPosition = other.clickPosition()

    @page.sendEvent('mousedown', position.x,      position.y)
    @page.sendEvent('mousemove', otherPosition.x, otherPosition.y)
    @page.sendEvent('mouseup',   otherPosition.x, otherPosition.y)

  isEqual: (other) ->
    @page == other.page && this.isDOMEqual(other.id)
