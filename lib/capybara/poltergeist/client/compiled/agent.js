var PoltergeistAgent;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
PoltergeistAgent = (function() {
  function PoltergeistAgent() {
    this.elements = [];
    this.nodes = {};
    this.windows = [];
    this.pushWindow(window);
  }
  PoltergeistAgent.prototype.pushWindow = function(new_window) {
    this.windows.push(new_window);
    this.window = new_window;
    return this.document = this.window.document;
  };
  PoltergeistAgent.prototype.popWindow = function() {
    this.windows.pop();
    this.window = this.windows[this.windows.length - 1];
    return this.document = this.window.document;
  };
  PoltergeistAgent.prototype.pushFrame = function(id) {
    return this.pushWindow(this.document.getElementById(id).contentWindow);
  };
  PoltergeistAgent.prototype.popFrame = function() {
    return this.popWindow();
  };
  PoltergeistAgent.prototype.currentUrl = function() {
    return window.location.toString();
  };
  PoltergeistAgent.prototype.find = function(selector, id) {
    var context, i, ids, results, _ref;
    context = id != null ? this.elements[id] : this.document;
    results = this.document.evaluate(selector, context, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
    ids = [];
    for (i = 0, _ref = results.snapshotLength; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
      ids.push(this.register(results.snapshotItem(i)));
    }
    return ids;
  };
  PoltergeistAgent.prototype.register = function(element) {
    this.elements.push(element);
    return this.elements.length - 1;
  };
  PoltergeistAgent.prototype.documentSize = function() {
    return {
      height: this.document.documentElement.scrollHeight,
      width: this.document.documentElement.scrollWidth
    };
  };
  PoltergeistAgent.prototype.get = function(id) {
    var _base;
    return (_base = this.nodes)[id] || (_base[id] = new PoltergeistAgent.Node(this, this.elements[id]));
  };
  PoltergeistAgent.prototype.nodeCall = function(id, name, arguments) {
    var node;
    node = this.get(id);
    return node[name].apply(node, arguments);
  };
  return PoltergeistAgent;
})();
PoltergeistAgent.Node = (function() {
  Node.EVENTS = {
    FOCUS: ['blur', 'focus', 'focusin', 'focusout'],
    MOUSE: ['click', 'dblclick', 'mousedown', 'mouseenter', 'mouseleave', 'mousemove', 'mouseover', 'mouseout', 'mouseup']
  };
  function Node(agent, element) {
    this.agent = agent;
    this.element = element;
  }
  Node.prototype.parentId = function() {
    return this.agent.register(this.element.parentNode);
  };
  Node.prototype.isObsolete = function() {
    var obsolete;
    obsolete = __bind(function(element) {
      if (element.parentNode != null) {
        if (element.parentNode === this.agent.document) {
          return false;
        } else {
          return obsolete(element.parentNode);
        }
      } else {
        return true;
      }
    }, this);
    return obsolete(this.element);
  };
  Node.prototype.changed = function() {
    var event;
    event = document.createEvent('HTMLEvents');
    event.initEvent("change", true, false);
    return this.element.dispatchEvent(event);
  };
  Node.prototype.insideBody = function() {
    return this.element === this.agent.document.body || this.agent.document.evaluate('ancestor::body', this.element, null, XPathResult.BOOLEAN_TYPE, null).booleanValue;
  };
  Node.prototype.text = function() {
    var el, i, results, text, _ref;
    if (this.insideBody()) {
      el = this.element;
    } else {
      el = this.agent.document.body;
    }
    results = this.agent.document.evaluate('.//text()[not(ancestor::script)]', el, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
    text = '';
    for (i = 0, _ref = results.snapshotLength; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
      text += results.snapshotItem(i).textContent;
    }
    return text;
  };
  Node.prototype.getAttribute = function(name) {
    if (name === 'checked' || name === 'selected') {
      return this.element[name];
    } else {
      return this.element.getAttribute(name);
    }
  };
  Node.prototype.value = function() {
    var option, _i, _len, _ref, _results;
    if (this.element.tagName === 'SELECT' && this.element.multiple) {
      _ref = this.element.children;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        option = _ref[_i];
        if (option.selected) {
          _results.push(option.value);
        }
      }
      return _results;
    } else {
      return this.element.value;
    }
  };
  Node.prototype.set = function(value) {
    if (this.element.maxLength >= 0) {
      value = value.substr(0, this.element.maxLength);
    }
    this.element.value = value;
    return this.changed();
  };
  Node.prototype.isMultiple = function() {
    return this.element.multiple;
  };
  Node.prototype.setAttribute = function(name, value) {
    return this.element.setAttribute(name, value);
  };
  Node.prototype.removeAttribute = function(name) {
    return this.element.removeAttribute(name);
  };
  Node.prototype.select = function(value) {
    if (value === false && !this.element.parentNode.multiple) {
      return false;
    } else {
      this.element.selected = value;
      this.changed();
      return true;
    }
  };
  Node.prototype.tagName = function() {
    return this.element.tagName;
  };
  Node.prototype.elementVisible = function(element) {};
  Node.prototype.isVisible = function(id) {
    var visible;
    visible = function(element) {
      if (this.window.getComputedStyle(element).display === 'none') {
        return false;
      } else if (element.parentElement) {
        return visible(element.parentElement);
      } else {
        return true;
      }
    };
    return visible(this.element);
  };
  Node.prototype.position = function(id) {
    var pos;
    pos = function(element) {
      var parentPos, x, y;
      x = element.offsetLeft;
      y = element.offsetTop;
      if (element.offsetParent) {
        parentPos = pos(element.offsetParent);
        x += parentPos.x;
        y += parentPos.y;
      }
      return {
        x: x,
        y: y
      };
    };
    return pos(this.element);
  };
  Node.prototype.trigger = function(name) {
    var event;
    if (Node.EVENTS.MOUSE.indexOf(name) !== -1) {
      event = document.createEvent('MouseEvent');
      event.initMouseEvent(name, true, true, this.agent.window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
    } else if (Node.EVENTS.FOCUS.indexOf(name) !== -1) {
      event = document.createEvent('HTMLEvents');
      event.initEvent(name, true, true);
    } else {
      throw "Unknown event";
    }
    return this.element.dispatchEvent(event);
  };
  return Node;
})();
window.__poltergeist = new PoltergeistAgent;
document.addEventListener('DOMContentLoaded', function() {
  return console.log('__DOMContentLoaded');
});