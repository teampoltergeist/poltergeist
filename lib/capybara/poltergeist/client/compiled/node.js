var slice = [].slice;

Poltergeist.Node = (function() {
  var fn, j, len, name, ref;

  Node.DELEGATES = ['allText', 'visibleText', 'getAttribute', 'value', 'set', 'setAttribute', 'isObsolete', 'removeAttribute', 'isMultiple', 'select', 'tagName', 'find', 'getAttributes', 'isVisible', 'isInViewport', 'position', 'trigger', 'parentId', 'parentIds', 'mouseEventTest', 'scrollIntoView', 'isDOMEqual', 'isDisabled', 'deleteText', 'containsSelection', 'path', 'getProperty'];

  function Node(page, id) {
    this.page = page;
    this.id = id;
  }

  Node.prototype.parent = function() {
    return new Poltergeist.Node(this.page, this.parentId());
  };

  ref = Node.DELEGATES;
  fn = function(name) {
    return Node.prototype[name] = function() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return this.page.nodeCall(this.id, name, args);
    };
  };
  for (j = 0, len = ref.length; j < len; j++) {
    name = ref[j];
    fn(name);
  }

  Node.prototype.mouseEventPosition = function() {
    var area_offset, image, middle, pos, res, viewport;
    viewport = this.page.viewportSize();
    if (image = this._getAreaImage()) {
      pos = image.position();
      if (area_offset = this._getAreaOffsetRect()) {
        pos.left = pos.left + area_offset.x;
        pos.right = pos.left + area_offset.width;
        pos.top = pos.top + area_offset.y;
        pos.bottom = pos.top + area_offset.height;
      }
    } else {
      pos = this.position();
    }
    middle = function(start, end, size) {
      return start + ((Math.min(end, size) - start) / 2);
    };
    return res = {
      x: middle(pos.left, pos.right, viewport.width),
      y: middle(pos.top, pos.bottom, viewport.height)
    };
  };

  Node.prototype.mouseEvent = function(name) {
    var area_image, pos, test;
    if (area_image = this._getAreaImage()) {
      area_image.scrollIntoView();
    } else {
      this.scrollIntoView();
    }
    pos = this.mouseEventPosition();
    test = this.mouseEventTest(pos.x, pos.y);
    if (test.status === 'success') {
      if (name === 'rightclick') {
        this.page.mouseEvent('click', pos.x, pos.y, 'right');
        this.trigger('contextmenu');
      } else {
        this.page.mouseEvent(name, pos.x, pos.y);
      }
      return pos;
    } else {
      throw new Poltergeist.MouseEventFailed(name, test.selector, pos);
    }
  };

  Node.prototype.dragTo = function(other) {
    var otherPosition, position;
    this.scrollIntoView();
    position = this.mouseEventPosition();
    otherPosition = other.mouseEventPosition();
    this.page.mouseEvent('mousedown', position.x, position.y);
    return this.page.mouseEvent('mouseup', otherPosition.x, otherPosition.y);
  };

  Node.prototype.dragBy = function(x, y) {
    var final_pos, position;
    this.scrollIntoView();
    position = this.mouseEventPosition();
    final_pos = {
      x: position.x + x,
      y: position.y + y
    };
    this.page.mouseEvent('mousedown', position.x, position.y);
    return this.page.mouseEvent('mouseup', final_pos.x, final_pos.y);
  };

  Node.prototype.isEqual = function(other) {
    return this.page === other.page && this.isDOMEqual(other.id);
  };

  Node.prototype._getAreaOffsetRect = function() {
    var centerX, centerY, coord, coords, i, maxX, maxY, minX, minY, radius, rect, shape, x, xs, y, ys;
    shape = this.getAttribute('shape').toLowerCase();
    coords = (function() {
      var k, len1, ref1, results;
      ref1 = this.getAttribute('coords').split(',');
      results = [];
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        coord = ref1[k];
        results.push(parseInt(coord, 10));
      }
      return results;
    }).call(this);
    return rect = (function() {
      switch (shape) {
        case 'rect':
        case 'rectangle':
          x = coords[0], y = coords[1];
          return {
            x: x,
            y: y,
            width: coords[2] - x,
            height: coords[3] - y
          };
        case 'circ':
        case 'circle':
          centerX = coords[0], centerY = coords[1], radius = coords[2];
          return {
            x: centerX - radius,
            y: centerY - radius,
            width: 2 * radius,
            height: 2 * radius
          };
        case 'poly':
        case 'polygon':
          xs = (function() {
            var k, ref1, results;
            results = [];
            for (i = k = 0, ref1 = coords.length; k < ref1; i = k += 2) {
              results.push(coords[i]);
            }
            return results;
          })();
          ys = (function() {
            var k, ref1, results;
            results = [];
            for (i = k = 1, ref1 = coords.length; k < ref1; i = k += 2) {
              results.push(coords[i]);
            }
            return results;
          })();
          minX = Math.min.apply(Math, xs);
          maxX = Math.max.apply(Math, xs);
          minY = Math.min.apply(Math, ys);
          maxY = Math.max.apply(Math, ys);
          return {
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
          };
      }
    })();
  };

  Node.prototype._getAreaImage = function() {
    var image_node_id, map, mapName;
    if ('area' === this.tagName().toLowerCase()) {
      map = this.parent();
      if (map.tagName().toLowerCase() !== 'map') {
        throw new Error('the area is not within a map');
      }
      mapName = map.getAttribute('name');
      if (mapName == null) {
        throw new Error("area's parent map must have a name");
      }
      mapName = '#' + mapName.toLowerCase();
      image_node_id = this.page.find('css', "img[usemap='" + mapName + "']")[0];
      if (image_node_id == null) {
        throw new Error("no image matches the map");
      }
      return this.page.get(image_node_id);
    }
  };

  return Node;

})();
