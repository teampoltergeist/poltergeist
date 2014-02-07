var Poltergeist,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Poltergeist = (function() {
  function Poltergeist(port, width, height) {
    this.browser = new Poltergeist.Browser(this, width, height);
    this.connection = new Poltergeist.Connection(this, port);
    phantom.onError = (function(_this) {
      return function(message, stack) {
        return _this.onError(message, stack);
      };
    })(this);
    this.running = false;
  }

  Poltergeist.prototype.runCommand = function(command) {
    var error;
    this.running = true;
    try {
      return this.browser.runCommand(command.name, command.args);
    } catch (_error) {
      error = _error;
      if (error instanceof Poltergeist.Error) {
        return this.sendError(error);
      } else {
        return this.sendError(new Poltergeist.BrowserError(error.toString(), error.stack));
      }
    }
  };

  Poltergeist.prototype.sendResponse = function(response) {
    return this.send({
      response: response
    });
  };

  Poltergeist.prototype.sendError = function(error) {
    return this.send({
      error: {
        name: error.name || "Generic",
        args: error.args && error.args() || [error.toString()]
      }
    });
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

Poltergeist.ObsoleteNode = (function(_super) {
  __extends(ObsoleteNode, _super);

  function ObsoleteNode() {
    return ObsoleteNode.__super__.constructor.apply(this, arguments);
  }

  ObsoleteNode.prototype.name = "Poltergeist.ObsoleteNode";

  ObsoleteNode.prototype.args = function() {
    return [];
  };

  ObsoleteNode.prototype.toString = function() {
    return this.name;
  };

  return ObsoleteNode;

})(Poltergeist.Error);

Poltergeist.InvalidSelector = (function(_super) {
  __extends(InvalidSelector, _super);

  function InvalidSelector(method, selector) {
    this.method = method;
    this.selector = selector;
  }

  InvalidSelector.prototype.name = "Poltergeist.InvalidSelector";

  InvalidSelector.prototype.args = function() {
    return [this.method, this.selector];
  };

  return InvalidSelector;

})(Poltergeist.Error);

Poltergeist.FrameNotFound = (function(_super) {
  __extends(FrameNotFound, _super);

  function FrameNotFound(frameName) {
    this.frameName = frameName;
  }

  FrameNotFound.prototype.name = "Poltergeist.FrameNotFound";

  FrameNotFound.prototype.args = function() {
    return [this.frameName];
  };

  return FrameNotFound;

})(Poltergeist.Error);

Poltergeist.MouseEventFailed = (function(_super) {
  __extends(MouseEventFailed, _super);

  function MouseEventFailed(eventName, selector, position) {
    this.eventName = eventName;
    this.selector = selector;
    this.position = position;
  }

  MouseEventFailed.prototype.name = "Poltergeist.MouseEventFailed";

  MouseEventFailed.prototype.args = function() {
    return [this.eventName, this.selector, this.position];
  };

  return MouseEventFailed;

})(Poltergeist.Error);

Poltergeist.JavascriptError = (function(_super) {
  __extends(JavascriptError, _super);

  function JavascriptError(errors) {
    this.errors = errors;
  }

  JavascriptError.prototype.name = "Poltergeist.JavascriptError";

  JavascriptError.prototype.args = function() {
    return [this.errors];
  };

  return JavascriptError;

})(Poltergeist.Error);

Poltergeist.BrowserError = (function(_super) {
  __extends(BrowserError, _super);

  function BrowserError(message, stack) {
    this.message = message;
    this.stack = stack;
  }

  BrowserError.prototype.name = "Poltergeist.BrowserError";

  BrowserError.prototype.args = function() {
    return [this.message, this.stack];
  };

  return BrowserError;

})(Poltergeist.Error);

phantom.injectJs("" + phantom.libraryPath + "/web_page.js");

phantom.injectJs("" + phantom.libraryPath + "/node.js");

phantom.injectJs("" + phantom.libraryPath + "/connection.js");

phantom.injectJs("" + phantom.libraryPath + "/browser.js");

(function(func, args, ctor) {
  ctor.prototype = func.prototype;
  var child = new ctor, result = func.apply(child, args);
  return Object(result) === result ? result : child;
})(Poltergeist, phantom.args, function(){});
