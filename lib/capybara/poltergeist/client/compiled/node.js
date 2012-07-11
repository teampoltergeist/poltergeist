var __slice = [].slice;

Poltergeist.Node = (function() {
  var name, _fn, _i, _len, _ref,
    _this = this;

  Node.DELEGATES = ['text', 'getAttribute', 'value', 'set', 'setAttribute', 'isObsolete', 'removeAttribute', 'isMultiple', 'select', 'tagName', 'find', 'isVisible', 'position', 'trigger', 'parentId', 'clickTest', 'scrollIntoView'];

  function Node(page, id) {
    this.page = page;
    this.id = id;
  }

  Node.prototype.parent = function() {
    return new Poltergeist.Node(this.page, this.parentId());
  };

  _ref = Node.DELEGATES;
  _fn = function(name) {
    return Node.prototype[name] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.page.nodeCall(this.id, name, args);
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    name = _ref[_i];
    _fn(name);
  }

  Node.prototype.clickPosition = function(scrollIntoView) {
    var middle, pos, viewport;
    if (scrollIntoView == null) {
      scrollIntoView = true;
    }
    if (scrollIntoView) {
      this.scrollIntoView();
    }
    viewport = this.page.viewportSize();
    pos = this.position();
    middle = function(start, end, size) {
      return start + ((Math.min(end, size) - start) / 2);
    };
    return {
      x: middle(pos.left, pos.right, viewport.width),
      y: middle(pos.top, pos.bottom, viewport.height)
    };
  };

  Node.prototype.click = function() {
    var pos, test;
    pos = this.clickPosition();
    test = this.clickTest(pos.x, pos.y);
    if (test.status === 'success') {
      return this.page.sendEvent('click', pos.x, pos.y);
    } else {
      throw new Poltergeist.ClickFailed(test.selector, pos);
    }
  };

  Node.prototype.dragTo = function(other) {
    var otherPosition, position;
    position = this.clickPosition();
    otherPosition = other.clickPosition(false);
    this.page.sendEvent('mousedown', position.x, position.y);
    this.page.sendEvent('mousemove', otherPosition.x, otherPosition.y);
    return this.page.sendEvent('mouseup', otherPosition.x, otherPosition.y);
  };

  return Node;

}).call(this);
