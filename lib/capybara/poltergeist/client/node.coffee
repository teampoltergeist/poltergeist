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
    dimensions = @page.validatedDimensions()
    document   = dimensions.document
    viewport   = dimensions.viewport
    pos        = this.position()

    scroll = { left: dimensions.left, top: dimensions.top }

    unless dimensions.left <= pos.x < dimensions.right
      scroll.left = Math.min(pos.x, document.width - viewport.width)

    unless dimensions.top <= pos.y < dimensions.bottom
      scroll.top = Math.min(pos.y, document.height - viewport.height)

    if scroll.left != dimensions.left || scroll.top != dimensions.top
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
