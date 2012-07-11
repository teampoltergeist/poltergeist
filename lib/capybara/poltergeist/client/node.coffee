# Proxy object for forwarding method calls to the node object inside the page.

class Poltergeist.Node
  @DELEGATES = ['text', 'getAttribute', 'value', 'set', 'setAttribute', 'isObsolete',
                'removeAttribute', 'isMultiple', 'select', 'tagName', 'find',
                'isVisible', 'position', 'trigger', 'parentId', 'clickTest', 'scrollIntoView']

  constructor: (@page, @id) ->

  parent: ->
    new Poltergeist.Node(@page, this.parentId())

  for name in @DELEGATES
    do (name) =>
      this.prototype[name] = (args...) ->
        @page.nodeCall(@id, name, args)

  clickPosition: (scrollIntoView = true) ->
    if scrollIntoView
      this.scrollIntoView()

    viewport = @page.viewportSize()
    pos      = this.position()

    middle = (start, end, size) ->
      start + ((Math.min(end, size) - start) / 2)

    {
      x: middle(pos.left, pos.right,  viewport.width),
      y: middle(pos.top,  pos.bottom, viewport.height)
    }

  click: ->
    pos  = this.clickPosition()
    test = this.clickTest(pos.x, pos.y)

    if test.status == 'success'
      @page.sendEvent('click', pos.x, pos.y)
    else
      throw new Poltergeist.ClickFailed(test.selector, pos)

  dragTo: (other) ->
    position      = this.clickPosition()
    otherPosition = other.clickPosition(false)

    @page.sendEvent('mousedown', position.x,      position.y)
    @page.sendEvent('mousemove', otherPosition.x, otherPosition.y)
    @page.sendEvent('mouseup',   otherPosition.x, otherPosition.y)
