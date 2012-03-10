var Poltergeist;
Poltergeist = (function() {
  function Poltergeist(port) {
    this.browser = new Poltergeist.Browser(this);
    this.connection = new Poltergeist.Connection(this, port);
  }
  Poltergeist.prototype.runCommand = function(command) {
    try {
      return this.browser[command.name].apply(this.browser, command.args);
    } catch (error) {
      return this.sendError(error);
    }
  };
  Poltergeist.prototype.sendResponse = function(response) {
    return this.connection.send({
      response: response
    });
  };
  Poltergeist.prototype.sendError = function(error) {
    return this.connection.send({
      error: {
        name: error.name || 'Generic',
        args: error.args && error.args() || [error.toString()]
      }
    });
  };
  return Poltergeist;
})();
window.Poltergeist = Poltergeist;
Poltergeist.ObsoleteNode = (function() {
  function ObsoleteNode() {}
  ObsoleteNode.prototype.name = "Poltergeist.ObsoleteNode";
  ObsoleteNode.prototype.args = function() {
    return [];
  };
  return ObsoleteNode;
})();
Poltergeist.ClickFailed = (function() {
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
  function JavascriptError(errors) {
    this.errors = errors;
  }
  JavascriptError.prototype.name = "Poltergeist.JavascriptError";
  JavascriptError.prototype.args = function() {
    return [this.errors];
  };
  return JavascriptError;
})();
phantom.injectJs('web_page.js');
phantom.injectJs('node.js');
phantom.injectJs('connection.js');
phantom.injectJs('browser.js');
new Poltergeist(phantom.args[0]);