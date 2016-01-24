# Proxy object for forwarding method calls to the node object inside the page.

class Poltergeist.Node
  @DELEGATES = ['allText', 'visibleText', 'getAttribute', 'value', 'set', 'setAttribute', 'isObsolete',
                'removeAttribute', 'isMultiple', 'select', 'tagName', 'find', 'getAttributes',
                'isVisible', 'isInViewport', 'position', 'trigger', 'parentId', 'parentIds', 'mouseEventTest',
                'scrollIntoView', 'isDOMEqual', 'isDisabled', 'deleteText', 'containsSelection',
                'path', 'getProperty']

  constructor: (@page, @id) ->

  parent: ->
    new Poltergeist.Node(@page, this.parentId())

  for name in @DELEGATES
    do (name) =>
      this.prototype[name] = (args...) ->
        @page.nodeCall(@id, name, args)

  mouseEventPosition: ->
    viewport = @page.viewportSize()

    if image = @_getAreaImage()
      pos = image.position()

      if area_offset = @_getAreaOffsetRect()
        pos.left = pos.left + area_offset.x
        pos.right = pos.left + area_offset.width
        pos.top = pos.top + area_offset.y
        pos.bottom = pos.top + area_offset.height
    else
      pos = this.position()

    middle = (start, end, size) ->
      start + ((Math.min(end, size) - start) / 2)

    res = {
      x: middle(pos.left, pos.right,  viewport.width),
      y: middle(pos.top,  pos.bottom, viewport.height)
    }


  mouseEvent: (name) ->
    if area_image = @_getAreaImage()
      area_image.scrollIntoView()
    else
      @scrollIntoView()
    pos = this.mouseEventPosition()
    test = this.mouseEventTest(pos.x, pos.y)
    if test.status == 'success'
      if name == 'rightclick'
        @page.mouseEvent('click', pos.x, pos.y, 'right')
        this.trigger('contextmenu')
      else
        @page.mouseEvent(name, pos.x, pos.y)
      pos
    else
      throw new Poltergeist.MouseEventFailed(name, test.selector, pos)

  dragTo: (other) ->
    this.scrollIntoView()

    position      = this.mouseEventPosition()
    otherPosition = other.mouseEventPosition()

    @page.mouseEvent('mousedown', position.x,      position.y)
    @page.mouseEvent('mouseup',   otherPosition.x, otherPosition.y)

  dragBy: (x, y) ->
    this.scrollIntoView()

    position      = this.mouseEventPosition()

    final_pos =
      x: position.x + x
      y: position.y + y

    @page.mouseEvent('mousedown', position.x, position.y)
    @page.mouseEvent('mouseup', final_pos.x, final_pos.y)


  isEqual: (other) ->
    @page == other.page && this.isDOMEqual(other.id)

  _getAreaOffsetRect: ->
    # get the offset of the center of selected area
    shape = @getAttribute('shape').toLowerCase();
    coords = (parseInt(coord,10) for coord in @getAttribute('coords').split(','))

    rect = switch shape
      when 'rect', 'rectangle'
        #coords.length == 4
        [x,y] = coords
        { x: x, y: y, width: coords[2] - x, height: coords[3] - y }
      when 'circ', 'circle'
        # coords.length == 3
        [centerX, centerY, radius] = coords
        { x: centerX - radius, y: centerY - radius, width: 2 * radius, height: 2 * radius }
      when 'poly', 'polygon'
        # coords.length > 2
        # This isn't correct for highly concave polygons but is probably good enough for
        # use in a testing tool
        xs = (coords[i] for i in [0...coords.length] by 2)
        ys = (coords[i] for i in [1...coords.length] by 2)
        minX = Math.min xs...
        maxX = Math.max xs...
        minY = Math.min ys...
        maxY = Math.max ys...
        { x: minX, y: minY, width: maxX-minX, height: maxY-minY }

  _getAreaImage: ->
    if 'area' == @tagName().toLowerCase()
      map = @parent()
      if map.tagName().toLowerCase() != 'map'
        throw new Error('the area is not within a map')

      mapName = map.getAttribute('name')
      if not mapName?
        throw new Error ("area's parent map must have a name")
      mapName = '#' + mapName.toLowerCase()

      image_node_id = @page.find('css', "img[usemap='#{mapName}']")[0]
      if not image_node_id?
        throw new Error ("no image matches the map")

      @page.get(image_node_id)

