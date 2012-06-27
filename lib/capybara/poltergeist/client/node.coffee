# Proxy object for forwarding method calls to the node object inside the page.

class Poltergeist.Node
  @DELEGATES = ['text', 'getAttribute', 'value', 'set', 'setAttribute', 'isObsolete',
                'removeAttribute', 'isMultiple', 'select', 'tagName', 'find',
                'isVisible', 'position', 'trigger', 'parentId', 'clickTest']

  constructor: (@page, @id) ->

  parent: ->
    new Poltergeist.Node(@page, this.parentId())

  for name in @DELEGATES
    do (name) =>
      this.prototype[name] = (args...) ->
        @page.nodeCall(@id, name, args)

  clickPosition: (scrollIntoView = true) ->
    dimensions = @page.validatedDimensions()
    document   = dimensions.document
    viewport   = dimensions.viewport
    pos        = this.position()

    scroll = { left: dimensions.left, top: dimensions.top }

    adjust = (coord, measurement) ->
      if pos[coord] < 0
        scroll[coord] = Math.max(
          0,
          scroll[coord] + pos[coord] - (viewport[measurement] / 2)
        )

      else if pos[coord] >= viewport[measurement]
        scroll[coord] = Math.min(
          document[measurement] - viewport[measurement],
          scroll[coord] + pos[coord] - viewport[measurement] + (viewport[measurement] / 2)
        )

    if scrollIntoView
      adjust('left', 'width')
      adjust('top',  'height')

      if scroll.left != dimensions.left || scroll.top != dimensions.top
        @page.setScrollPosition(scroll)
        pos = this.position()

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
