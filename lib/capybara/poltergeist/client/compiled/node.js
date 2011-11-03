var __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
Poltergeist.Node = (function() {
  var name, _fn, _i, _len, _ref;
  Node.DELEGATES = ['text', 'getAttribute', 'value', 'set', 'setAttribute', 'removeAttribute', 'isMultiple', 'select', 'tagName', 'isVisible', 'position', 'trigger', 'parentId'];
  function Node(page, id) {
    this.page = page;
    this.id = id;
  }
  Node.prototype.parent = function() {
    return new Poltergeist.Node(this.page, this.parentId());
  };
  Node.prototype.isObsolete = function() {
    return this.page.nodeCall(this.id, 'isObsolete');
  };
  _ref = Node.DELEGATES;
  _fn = __bind(function(name) {
    return this.prototype[name] = function() {
      var arguments, _ref2;
      _ref2 = arguments, arguments = 1 <= _ref2.length ? __slice.call(_ref2, 0) : [];
      if (this.isObsolete()) {
        throw new Poltergeist.ObsoleteNode;
      } else {
        return this.page.nodeCall(this.id, name, arguments);
      }
    };
  }, Node);
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    name = _ref[_i];
    _fn(name);
  }
  Node.prototype.scrollIntoView = function() {
    var dimensions, document, pos, scroll, viewport, _ref2, _ref3;
    dimensions = this.page.validatedDimensions();
    document = dimensions.document;
    viewport = dimensions.viewport;
    pos = this.position();
    scroll = {
      left: dimensions.left,
      top: dimensions.top
    };
    if (!((dimensions.left <= (_ref2 = pos.x) && _ref2 < dimensions.right))) {
      scroll.left = Math.min(pos.x, document.width - viewport.width);
    }
    if (!((dimensions.top <= (_ref3 = pos.y) && _ref3 < dimensions.bottom))) {
      scroll.top = Math.min(pos.y, document.height - viewport.height);
    }
    if (scroll.left !== dimensions.left || scroll.top !== dimensions.top) {
      this.page.setScrollPosition(scroll);
    }
    return {
      position: this.relativePosition(pos, scroll),
      scroll: scroll
    };
  };
  Node.prototype.relativePosition = function(position, scroll) {
    return {
      x: position.x - scroll.left,
      y: position.y - scroll.top
    };
  };
  Node.prototype.click = function() {
    var position;
    position = this.scrollIntoView().position;
    return this.page.sendEvent('click', position.x, position.y);
  };
  Node.prototype.dragTo = function(other) {
    var otherPosition, position, scroll, _ref2;
    _ref2 = this.scrollIntoView(), position = _ref2.position, scroll = _ref2.scroll;
    otherPosition = this.relativePosition(other.position(), scroll);
    this.page.sendEvent('mousedown', position.x, position.y);
    this.page.sendEvent('mousemove', otherPosition.x, otherPosition.y);
    return this.page.sendEvent('mouseup', otherPosition.x, otherPosition.y);
  };
  return Node;
}).call(this);