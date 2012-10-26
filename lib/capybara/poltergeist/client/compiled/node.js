var __slice = [].slice;

Poltergeist.Node = (function() {
  var name, _fn, _i, _len, _ref,
    _this = this;

  Node.DELEGATES = ['text', 'getAttribute', 'value', 'setAttribute', 'isObsolete', 'removeAttribute', 'isMultiple', 'select', 'tagName', 'find', 'isVisible', 'position', 'trigger', 'parentId', 'clickTest', 'scrollIntoView', 'isDOMEqual', 'focusAndHighlight', 'blur'];

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

  Node.prototype.clickPosition = function() {
    var middle, pos, viewport;
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
    this.scrollIntoView();
    pos = this.clickPosition();
    test = this.clickTest(pos.x, pos.y);
    if (test.status === 'success') {
      this.page.mouseEvent('click', pos.x, pos.y);
      return pos;
    } else {
      throw new Poltergeist.ClickFailed(test.selector, pos);
    }
  };

  Node.prototype.dragTo = function(other) {
    var otherPosition, position;
    this.scrollIntoView();
    position = this.clickPosition();
    otherPosition = other.clickPosition();
    this.page.mouseEvent('mousedown', position.x, position.y);
    return this.page.mouseEvent('mouseup', otherPosition.x, otherPosition.y);
  };

  Node.prototype.isEqual = function(other) {
    return this.page === other.page && this.isDOMEqual(other.id);
  };

  Node.prototype.set = function(value) {
    this.focusAndHighlight();
    this.page.sendEvent('keypress', 16777219);
    this.page.sendEvent('keypress', value.toString());
    return this.blur();
  };

  return Node;

}).call(this);
