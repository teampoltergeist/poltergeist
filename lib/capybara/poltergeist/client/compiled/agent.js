var PoltergeistAgent;

PoltergeistAgent = (function() {

  function PoltergeistAgent() {
    this.elements = [];
    this.nodes = {};
  }

  PoltergeistAgent.prototype.externalCall = function(name, args) {
    try {
      return {
        value: this[name].apply(this, args)
      };
    } catch (error) {
      return {
        error: {
          message: error.toString(),
          stack: error.stack
        }
      };
    }
  };

  PoltergeistAgent.stringify = function(object) {
    try {
      return JSON.stringify(object, function(key, value) {
        if (Array.isArray(this[key])) {
          return this[key];
        } else {
          return value;
        }
      });
    } catch (error) {
      if (error instanceof TypeError) {
        return '"(cyclic structure)"';
      } else {
        throw error;
      }
    }
  };

  PoltergeistAgent.prototype.currentUrl = function() {
    return window.location.toString();
  };

  PoltergeistAgent.prototype.find = function(selector, within) {
    var i, ids, results, _i, _ref;
    if (within == null) {
      within = document;
    }
    results = document.evaluate(selector, within, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
    ids = [];
    for (i = _i = 0, _ref = results.snapshotLength; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
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
      height: document.documentElement.scrollHeight,
      width: document.documentElement.scrollWidth
    };
  };

  PoltergeistAgent.prototype.get = function(id) {
    var _base;
    return (_base = this.nodes)[id] || (_base[id] = new PoltergeistAgent.Node(this, this.elements[id]));
  };

  PoltergeistAgent.prototype.nodeCall = function(id, name, args) {
    var node;
    node = this.get(id);
    if (node.isObsolete()) {
      throw new PoltergeistAgent.ObsoleteNode;
    }
    return node[name].apply(node, args);
  };

  return PoltergeistAgent;

})();

PoltergeistAgent.ObsoleteNode = (function() {

  function ObsoleteNode() {}

  ObsoleteNode.prototype.toString = function() {
    return "PoltergeistAgent.ObsoleteNode";
  };

  return ObsoleteNode;

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

  Node.prototype.find = function(selector) {
    return this.agent.find(selector, this.element);
  };

  Node.prototype.isObsolete = function() {
    var obsolete,
      _this = this;
    obsolete = function(element) {
      if (element.parentNode != null) {
        if (element.parentNode === document) {
          return false;
        } else {
          return obsolete(element.parentNode);
        }
      } else {
        return true;
      }
    };
    return obsolete(this.element);
  };

  Node.prototype.changed = function() {
    var event;
    event = document.createEvent('HTMLEvents');
    event.initEvent('change', true, false);
    return this.element.dispatchEvent(event);
  };

  Node.prototype.insideBody = function() {
    return this.element === document.body || document.evaluate('ancestor::body', this.element, null, XPathResult.BOOLEAN_TYPE, null).booleanValue;
  };

  Node.prototype.text = function() {
    if (this.element.tagName === 'TEXTAREA') {
      return this.element.textContent;
    } else {
      return this.element.innerText;
    }
  };

  Node.prototype.getAttribute = function(name) {
    if (name === 'checked' || name === 'selected') {
      return this.element[name];
    } else {
      return this.element.getAttribute(name);
    }
  };

  Node.prototype.scrollIntoView = function() {
    return this.element.scrollIntoViewIfNeeded();
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

  Node.prototype.isVisible = function(element) {
    if (!element) {
      element = this.element;
    }
    if (window.getComputedStyle(element).display === 'none') {
      return false;
    } else if (element.parentElement) {
      return this.isVisible(element.parentElement);
    } else {
      return true;
    }
  };

  Node.prototype.position = function() {
    var rect;
    rect = this.element.getClientRects()[0];
    if (!rect) {
      throw new PoltergeistAgent.ObsoleteNode;
    }
    return {
      top: rect.top,
      right: rect.right,
      left: rect.left,
      bottom: rect.bottom,
      width: rect.width,
      height: rect.height
    };
  };

  Node.prototype.trigger = function(name) {
    var event;
    if (Node.EVENTS.MOUSE.indexOf(name) !== -1) {
      event = document.createEvent('MouseEvent');
      event.initMouseEvent(name, true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
    } else if (Node.EVENTS.FOCUS.indexOf(name) !== -1) {
      event = document.createEvent('HTMLEvents');
      event.initEvent(name, true, true);
    } else {
      throw "Unknown event";
    }
    return this.element.dispatchEvent(event);
  };

  Node.prototype.focusAndHighlight = function() {
    this.element.focus();
    return this.element.select();
  };

  Node.prototype.blur = function() {
    return this.element.blur();
  };

  Node.prototype.clickTest = function(x, y) {
    var el, origEl;
    el = origEl = document.elementFromPoint(x, y);
    while (el) {
      if (el === this.element) {
        return {
          status: 'success'
        };
      } else {
        el = el.parentNode;
      }
    }
    return {
      status: 'failure',
      selector: origEl && this.getSelector(origEl)
    };
  };

  Node.prototype.getSelector = function(el) {
    var className, selector, _i, _len, _ref;
    selector = el.tagName !== 'HTML' ? this.getSelector(el.parentNode) + ' ' : '';
    selector += el.tagName.toLowerCase();
    if (el.id) {
      selector += "#" + el.id;
    }
    _ref = el.classList;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      className = _ref[_i];
      selector += "." + className;
    }
    return selector;
  };

  Node.prototype.isDOMEqual = function(other_id) {
    return this.element === this.agent.get(other_id).element;
  };

  return Node;

})();

window.__poltergeist = new PoltergeistAgent;

document.addEventListener('DOMContentLoaded', function() {
  return console.log('__DOMContentLoaded');
});

window.confirm = function(message) {
  return true;
};

window.prompt = function(message, _default) {
  return _default || null;
};
