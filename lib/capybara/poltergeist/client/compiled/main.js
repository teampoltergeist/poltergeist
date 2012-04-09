var Poltergeist;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
};
Poltergeist = (function() {
  function Poltergeist(port) {
    this.onError = __bind(this.onError, this);
    var that;
    this.browser = new Poltergeist.Browser(this);
    this.connection = new Poltergeist.Connection(this, port);
    that = this;
    phantom.onError = function(message, stack) {
      return that.onError(message, stack);
    };
    this.running = false;
  }
  Poltergeist.prototype.runCommand = function(command) {
    this.running = true;
    return this.browser[command.name].apply(this.browser, command.args);
  };
  Poltergeist.prototype.sendResponse = function(response) {
    return this.send({
      response: response
    });
  };
  Poltergeist.prototype.sendError = function(error) {
    return this.send({
      error: {
        name: error.name || 'Generic',
        args: error.args && error.args() || [error.toString()]
      }
    });
  };
  Poltergeist.prototype.onError = function(message, stack) {
    if (message === 'PoltergeistAgent.ObsoleteNode') {
      return this.sendError(new Poltergeist.ObsoleteNode);
    } else {
      return this.sendError(new Poltergeist.BrowserError(message, stack));
    }
  };
  Poltergeist.prototype.send = function(data) {
    if (this.running) {
      this.connection.send(data);
      return this.running = false;
    }
  };
  return Poltergeist;
})();
window.Poltergeist = Poltergeist;
Poltergeist.Error = (function() {
  function Error() {}
  return Error;
})();
Poltergeist.ObsoleteNode = (function() {
  __extends(ObsoleteNode, Poltergeist.Error);
  function ObsoleteNode() {
    ObsoleteNode.__super__.constructor.apply(this, arguments);
  }
  ObsoleteNode.prototype.name = "Poltergeist.ObsoleteNode";
  ObsoleteNode.prototype.args = function() {
    return [];
  };
  ObsoleteNode.prototype.toString = function() {
    return this.name;
  };
  return ObsoleteNode;
})();
Poltergeist.ClickFailed = (function() {
  __extends(ClickFailed, Poltergeist.Error);
  function ClickFailed(selector, position) {
    this.selector = selector;
    this.position = position;
  }
  ClickFailed.prototype.name = "Poltergeist.ClickFailed";
  ClickFailed.prototype.args = function() {
    return [this.selector, this.position];
  };
  return ClickFailed;
})();
Poltergeist.JavascriptError = (function() {
  __extends(JavascriptError, Poltergeist.Error);
  function JavascriptError(errors) {
    this.errors = errors;
  }
  JavascriptError.prototype.name = "Poltergeist.JavascriptError";
  JavascriptError.prototype.args = function() {
    return [this.errors];
  };
  return JavascriptError;
})();
Poltergeist.BrowserError = (function() {
  __extends(BrowserError, Poltergeist.Error);
  function BrowserError(message, stack) {
    this.message = message;
    this.stack = stack;
  }
  BrowserError.prototype.name = "Poltergeist.BrowserError";
  BrowserError.prototype.args = function() {
    return [this.message, this.stack];
  };
  return BrowserError;
})();
phantom.injectJs("" + phantom.libraryPath + "/web_page.js");
phantom.injectJs("" + phantom.libraryPath + "/node.js");
phantom.injectJs("" + phantom.libraryPath + "/connection.js");
phantom.injectJs("" + phantom.libraryPath + "/browser.js");
new Poltergeist(phantom.args[0]);