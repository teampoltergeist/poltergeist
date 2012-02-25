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
      return this.connection.send({
        error: {
          name: error.name && error.name() || 'Generic',
          args: error.args && error.args() || [error.toString()]
        }
      });
    }
  };
  Poltergeist.prototype.sendResponse = function(response) {
    return this.connection.send({
      response: response
    });
  };
  return Poltergeist;
})();
window.Poltergeist = Poltergeist;
Poltergeist.ObsoleteNode = (function() {
  function ObsoleteNode() {}
  ObsoleteNode.prototype.name = function() {
    return "Poltergeist.ObsoleteNode";
  };
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
  ClickFailed.prototype.name = function() {
    return "Poltergeist.ClickFailed";
  };
  ClickFailed.prototype.args = function() {
    return [this.selector, this.position];
  };
  return ClickFailed;
})();
phantom.injectJs('web_page.js');
phantom.injectJs('node.js');
phantom.injectJs('connection.js');
phantom.injectJs('browser.js');
new Poltergeist(phantom.args[0]);