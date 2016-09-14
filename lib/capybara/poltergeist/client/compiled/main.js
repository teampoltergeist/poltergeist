var Poltergeist, system,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Poltergeist = (function() {
  function Poltergeist(port, width, height) {
    this.browser = new Poltergeist.Browser(width, height);
    this.connection = new Poltergeist.Connection(this, port);
    phantom.onError = (function(_this) {
      return function(message, stack) {
        return _this.onError(message, stack);
      };
    })(this);
  }

  Poltergeist.prototype.runCommand = function(command) {
    return new Poltergeist.Cmd(this, command.id, command.name, command.args).run(this.browser);
  };

  Poltergeist.prototype.sendResponse = function(command_id, response) {
    return this.send({
      command_id: command_id,
      response: response
    });
  };

  Poltergeist.prototype.sendError = function(command_id, error) {
    return this.send({
      command_id: command_id,
      error: {
        name: error.name || 'Generic',
        args: error.args && error.args() || [error.toString()]
      }
    });
  };

  Poltergeist.prototype.send = function(data) {
    this.connection.send(data);
    return true;
  };

  return Poltergeist;

})();

window.Poltergeist = Poltergeist;

Poltergeist.Error = (function() {
  function Error() {}

  return Error;

})();

Poltergeist.ObsoleteNode = (function(superClass) {
  extend(ObsoleteNode, superClass);

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

Poltergeist.InvalidSelector = (function(superClass) {
  extend(InvalidSelector, superClass);

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

Poltergeist.FrameNotFound = (function(superClass) {
  extend(FrameNotFound, superClass);

  function FrameNotFound(frameName) {
    this.frameName = frameName;
  }

  FrameNotFound.prototype.name = "Poltergeist.FrameNotFound";

  FrameNotFound.prototype.args = function() {
    return [this.frameName];
  };

  return FrameNotFound;

})(Poltergeist.Error);

Poltergeist.MouseEventFailed = (function(superClass) {
  extend(MouseEventFailed, superClass);

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

Poltergeist.JavascriptError = (function(superClass) {
  extend(JavascriptError, superClass);

  function JavascriptError(errors) {
    this.errors = errors;
  }

  JavascriptError.prototype.name = "Poltergeist.JavascriptError";

  JavascriptError.prototype.args = function() {
    return [this.errors];
  };

  return JavascriptError;

})(Poltergeist.Error);

Poltergeist.BrowserError = (function(superClass) {
  extend(BrowserError, superClass);

  function BrowserError(message1, stack1) {
    this.message = message1;
    this.stack = stack1;
  }

  BrowserError.prototype.name = "Poltergeist.BrowserError";

  BrowserError.prototype.args = function() {
    return [this.message, this.stack];
  };

  return BrowserError;

})(Poltergeist.Error);

Poltergeist.StatusFailError = (function(superClass) {
  extend(StatusFailError, superClass);

  function StatusFailError(url, details) {
    this.url = url;
    this.details = details;
  }

  StatusFailError.prototype.name = "Poltergeist.StatusFailError";

  StatusFailError.prototype.args = function() {
    return [this.url, this.details];
  };

  return StatusFailError;

})(Poltergeist.Error);

Poltergeist.NoSuchWindowError = (function(superClass) {
  extend(NoSuchWindowError, superClass);

  function NoSuchWindowError() {
    return NoSuchWindowError.__super__.constructor.apply(this, arguments);
  }

  NoSuchWindowError.prototype.name = "Poltergeist.NoSuchWindowError";

  NoSuchWindowError.prototype.args = function() {
    return [];
  };

  return NoSuchWindowError;

})(Poltergeist.Error);

Poltergeist.UnsupportedFeature = (function(superClass) {
  extend(UnsupportedFeature, superClass);

  function UnsupportedFeature(message1) {
    this.message = message1;
  }

  UnsupportedFeature.prototype.name = "Poltergeist.UnsupportedFeature";

  UnsupportedFeature.prototype.args = function() {
    return [this.message, phantom.version];
  };

  return UnsupportedFeature;

})(Poltergeist.Error);

phantom.injectJs(phantom.libraryPath + "/web_page.js");

phantom.injectJs(phantom.libraryPath + "/node.js");

phantom.injectJs(phantom.libraryPath + "/connection.js");

phantom.injectJs(phantom.libraryPath + "/cmd.js");

phantom.injectJs(phantom.libraryPath + "/browser.js");

system = require('system');

new Poltergeist(system.args[1], system.args[2], system.args[3]);
