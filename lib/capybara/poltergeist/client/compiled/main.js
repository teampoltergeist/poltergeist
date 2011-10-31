var Poltergeist;
if (phantom.version.major < 1 || phantom.version.minor < 3) {
  console.log("Poltergeist requires a PhantomJS version of at least 1.3");
  phantom.exit(1);
}
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
        error: error.toString()
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
Poltergeist.ObsoleteNode = (function() {
  function ObsoleteNode() {}
  ObsoleteNode.prototype.toString = function() {
    return "Poltergeist.ObsoleteNode";
  };
  return ObsoleteNode;
})();
phantom.injectJs('web_page.js');
phantom.injectJs('node.js');
phantom.injectJs('connection.js');
phantom.injectJs('browser.js');
new Poltergeist(phantom.args[0]);