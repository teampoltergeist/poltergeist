# Proxy object for forwarding method calls to the node object inside the page.

class Poltergeist.Node
  @DELEGATES = ['text', 'getAttribute', 'value', 'set', 'setAttribute', 'removeAttribute',
                'isMultiple', 'select', 'tagName', 'isVisible', 'position', 'trigger', 'parentId']

  constructor: (@page, @id) ->

  parent: ->
    new Poltergeist.Node(@page, this.parentId())

  isObsolete: ->
    @page.nodeCall(@id, 'isObsolete')

  for name in @DELEGATES
    do (name) =>
      this.prototype[name] = (arguments...) ->
        if this.isObsolete()
          throw new Poltergeist.ObsoleteNode
        else
          @page.nodeCall(@id, name, arguments)

  scrollIntoView: ->
    viewport = @page.viewport()
    size     = @page.documentSize()
    pos      = this.position()

    scroll = { left: viewport.left, top: viewport.top }

    unless viewport.left <= pos.x < viewport.right
      scroll.left = Math.min(pos.x, size.width - viewport.width)

    unless viewport.top <= pos.y < viewport.bottom
      scroll.top = Math.min(pos.y, size.height - viewport.height)

    if scroll.left != viewport.left || scroll.top != viewport.top
      @page.setScrollPosition(scroll)

    position: this.relativePosition(pos, scroll),
    scroll:   scroll

  relativePosition: (position, scroll) ->
    x: position.x - scroll.left
    y: position.y - scroll.top

  click: ->
    position = this.scrollIntoView().position
    @page.sendEvent('click', position.x, position.y)

  dragTo: (other) ->
    { position, scroll } = this.scrollIntoView()
    otherPosition        = this.relativePosition(other.position(), scroll)

    @page.sendEvent('mousedown', position.x,      position.y)
    @page.sendEvent('mousemove', otherPosition.x, otherPosition.y)
    @page.sendEvent('mouseup',   otherPosition.x, otherPosition.y)
