Poltergeist.Cmd = (function() {
  function Cmd(owner, id, name, args) {
    this.owner = owner;
    this.id = id;
    this.name = name;
    this.args = args;
    this._response_sent = false;
  }

  Cmd.prototype.sendResponse = function(response) {
    var errors;
    errors = this.browser.currentPage.errors;
    this.browser.currentPage.clearErrors();
    if (errors.length > 0 && this.browser.js_errors) {
      return this.sendError(new Poltergeist.JavascriptError(errors));
    } else {
      if (!this._response_sent) {
        this.owner.sendResponse(this.id, response);
      }
      return this._response_sent = true;
    }
  };

  Cmd.prototype.sendError = function(errors) {
    if (!this._response_sent) {
      this.owner.sendError(this.id, errors);
    }
    return this._response_sent = true;
  };

  Cmd.prototype.run = function(browser) {
    var error;
    this.browser = browser;
    try {
      return this.browser.runCommand(this);
    } catch (error1) {
      error = error1;
      if (error instanceof Poltergeist.Error) {
        return this.sendError(error);
      } else {
        return this.sendError(new Poltergeist.BrowserError(error.toString(), error.stack));
      }
    }
  };

  return Cmd;

})();
