# Proxy object for forwarding method calls to the node object inside the page.

class Poltergeist.Node
  @DELEGATES = ['allText', 'visibleText', 'getAttribute', 'value', 'set', 'setAttribute', 'isObsolete',
                'removeAttribute', 'isMultiple', 'select', 'tagName', 'find',
                'isVisible', 'position', 'trigger', 'parentId', 'mouseEventTest',
                'scrollIntoView', 'isDOMEqual', 'isDisabled', 'deleteText']

  constructor: (@page, @id) ->

  parent: -> new Poltergeist.Node(@page, @parentId())

  for name in @DELEGATES
    do (name) => @::[name] = (args...) -> @page.nodeCall(@id, name, args)

  mouseEventPosition: ->
    viewport = @page.viewportSize()
    pos      = @position()

    middle = (start, end, size) -> start + ((Math.min(end, size) - start) / 2)

    x: middle(pos.left, pos.right,  viewport.width),
    y: middle(pos.top,  pos.bottom, viewport.height)

  mouseEvent: (name) ->
    @scrollIntoView()

    pos  = @mouseEventPosition()
    test = @mouseEventTest(pos.x, pos.y)

    if test.status is "success"
      @page.mouseEvent name, pos.x, pos.y
      pos
    else
      throw new Poltergeist.MouseEventFailed(name, test.selector, pos)

  dragTo: (other) ->
    @scrollIntoView()

    position      = @mouseEventPosition()
    otherPosition = other.mouseEventPosition()

    @page.mouseEvent "mousedown", position.x,      position.y
    @page.mouseEvent "mouseup",   otherPosition.x, otherPosition.y

  isEqual: (other) -> @page is other.page and @isDOMEqual(other.id)
