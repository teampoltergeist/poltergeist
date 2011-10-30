var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
Poltergeist.Browser = (function() {
  function Browser(owner) {
    this.owner = owner;
    this.awaiting_response = false;
    this.resetPage();
  }
  Browser.prototype.resetPage = function() {
    if (this.page != null) {
      this.page.release();
    }
    this.page = new Poltergeist.WebPage;
    return this.page.onLoadFinished = __bind(function(status) {
      if (this.awaiting_response) {
        this.owner.sendResponse(status);
        return this.awaiting_response = false;
      }
    }, this);
  };
  Browser.prototype.visit = function(url) {
    this.awaiting_response = true;
    return this.page.open(url);
  };
  Browser.prototype.current_url = function() {
    return this.owner.sendResponse(this.page.currentUrl());
  };
  Browser.prototype.body = function() {
    return this.owner.sendResponse(this.page.content());
  };
  Browser.prototype.source = function() {
    return this.owner.sendResponse(this.page.source());
  };
  Browser.prototype.find = function(selector, id) {
    return this.owner.sendResponse(this.page.find(selector, id));
  };
  Browser.prototype.text = function(id) {
    return this.owner.sendResponse(this.page.get(id).text());
  };
  Browser.prototype.attribute = function(id, name) {
    return this.owner.sendResponse(this.page.get(id).getAttribute(name));
  };
  Browser.prototype.value = function(id) {
    return this.owner.sendResponse(this.page.get(id).value());
  };
  Browser.prototype.set = function(id, value) {
    this.page.get(id).set(value);
    return this.owner.sendResponse(true);
  };
  Browser.prototype.select_file = function(id, value) {
    var element, multiple;
    element = this.page.get(id);
    multiple = element.isMultiple();
    if (multiple) {
      element.removeAttribute('multiple');
    }
    element.setAttribute('_poltergeist_selected', '');
    this.page.uploadFile('[_poltergeist_selected]', value);
    element.removeAttribute('_poltergeist_selected');
    if (multiple) {
      element.setAttribute('multiple', 'multiple');
    }
    return this.owner.sendResponse(true);
  };
  Browser.prototype.select = function(id, value) {
    return this.owner.sendResponse(this.page.get(id).select(value));
  };
  Browser.prototype.tag_name = function(id) {
    return this.owner.sendResponse(this.page.get(id).tagName());
  };
  Browser.prototype.visible = function(id) {
    return this.owner.sendResponse(this.page.get(id).isVisible());
  };
  Browser.prototype.evaluate = function(script) {
    return this.owner.sendResponse(this.page.evaluate("function() { return " + script + " }"));
  };
  Browser.prototype.execute = function(script) {
    this.page.execute("function() { return " + script + " }");
    return this.owner.sendResponse(true);
  };
  Browser.prototype.push_frame = function(id) {
    this.page.pushFrame(id);
    return this.owner.sendResponse(true);
  };
  Browser.prototype.pop_frame = function() {
    this.page.popFrame();
    return this.owner.sendResponse(true);
  };
  Browser.prototype.click = function(id) {
    var load_detected;
    load_detected = false;
    this.page.onLoadStarted = __bind(function() {
      this.awaiting_response = true;
      return load_detected = true;
    }, this);
    this.page.get(id).click();
    return setTimeout(__bind(function() {
      this.page.onLoadStarted = null;
      if (!load_detected) {
        return this.owner.sendResponse(true);
      }
    }, this), 10);
  };
  Browser.prototype.drag = function(id, other_id) {
    this.page.get(id).dragTo(this.page.get(other_id));
    return this.owner.sendResponse(true);
  };
  Browser.prototype.trigger = function(id, event) {
    this.page.get(id).trigger(event);
    return this.owner.sendResponse(event);
  };
  Browser.prototype.reset = function() {
    this.resetPage();
    return this.owner.sendResponse(true);
  };
  Browser.prototype.render = function(path) {
    this.page.render(path);
    return this.owner.sendResponse(true);
  };
  return Browser;
})();