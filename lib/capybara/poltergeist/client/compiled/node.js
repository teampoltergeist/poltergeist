var __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
Poltergeist.Node = (function() {
  var name, _fn, _i, _len, _ref;
  Node.DELEGATES = ['text', 'getAttribute', 'value', 'set', 'setAttribute', 'removeAttribute', 'isMultiple', 'select', 'tagName', 'isVisible', 'position', 'trigger', 'parentId', 'clickTest'];
  function Node(page, id) {
    this.page = page;
    this.id = id;
  }
  Node.prototype.parent = function() {
    return new Poltergeist.Node(this.page, this.parentId());
  };
  _ref = Node.DELEGATES;
  _fn = __bind(function(name) {
    return this.prototype[name] = function() {
      var arguments, _ref2;
      _ref2 = arguments, arguments = 1 <= _ref2.length ? __slice.call(_ref2, 0) : [];
      return this.page.nodeCall(this.id, name, arguments);
    };
  }, Node);
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    name = _ref[_i];
    _fn(name);
  }
  Node.prototype.scrollIntoView = function() {
    var adjust, dimensions, document, pos, scroll, viewport;
    dimensions = this.page.validatedDimensions();
    document = dimensions.document;
    viewport = dimensions.viewport;
    pos = this.position();
    scroll = {
      left: dimensions.left,
      top: dimensions.top
    };
    adjust = function(coord, measurement) {
      if (pos[coord] < 0) {
        return scroll[coord] = Math.max(0, scroll[coord] + pos[coord] - (viewport[measurement] / 2));
      } else if (pos[coord] >= viewport[measurement]) {
        return scroll[coord] = Math.min(document[measurement] - viewport[measurement], scroll[coord] + pos[coord] - viewport[measurement] + (viewport[measurement] / 2));
      }
    };
    adjust('left', 'width');
    adjust('top', 'height');
    if (scroll.left !== dimensions.left || scroll.top !== dimensions.top) {
      this.page.setScrollPosition(scroll);
      pos = this.position();
    }
    return pos;
  };
  Node.prototype.click = function() {
    var position, test;
    position = this.scrollIntoView();
    test = this.clickTest(position.left, position.top);
    if (test.status === 'success') {
      return this.page.sendEvent('click', position.left, position.top);
    } else {
      throw new Poltergeist.ClickFailed(test.selector, position);
    }
  };
  Node.prototype.dragTo = function(other) {
    var otherPosition, position;
    position = this.scrollIntoView();
    otherPosition = other.position();
    this.page.sendEvent('mousedown', position.left, position.top);
    this.page.sendEvent('mousemove', otherPosition.left, otherPosition.top);
    return this.page.sendEvent('mouseup', otherPosition.left, otherPosition.top);
  };
  return Node;
}).call(this);