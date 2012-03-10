var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
Poltergeist.Browser = (function() {
  function Browser(owner) {
    this.owner = owner;
    this.state = 'default';
    this.page_id = 0;
    this.resetPage();
  }
  Browser.prototype.resetPage = function() {
    if (this.page != null) {
      this.page.release();
    }
    this.page = new Poltergeist.WebPage;
    this.page.onLoadStarted = __bind(function() {
      if (this.state === 'clicked') {
        return this.state = 'loading';
      }
    }, this);
    this.page.onLoadFinished = __bind(function(status) {
      if (this.state === 'loading') {
        this.sendResponse(status);
        return this.state = 'default';
      }
    }, this);
    return this.page.onInitialized = __bind(function() {
      return this.page_id += 1;
    }, this);
  };
  Browser.prototype.sendResponse = function(response) {
    var errors;
    errors = this.page.errors();
    if (errors.length > 0) {
      this.page.clearErrors();
      return this.owner.sendError(new Poltergeist.JavascriptError(errors));
    } else {
      return this.owner.sendResponse(response);
    }
  };
  Browser.prototype.node = function(page_id, id) {
    if (page_id === this.page_id) {
      return this.page.get(id);
    } else {
      throw new Poltergeist.ObsoleteNode;
    }
  };
  Browser.prototype.visit = function(url) {
    this.state = 'loading';
    return this.page.open(url);
  };
  Browser.prototype.current_url = function() {
    return this.sendResponse(this.page.currentUrl());
  };
  Browser.prototype.body = function() {
    return this.sendResponse(this.page.content());
  };
  Browser.prototype.source = function() {
    return this.sendResponse(this.page.source());
  };
  Browser.prototype.find = function(selector) {
    return this.sendResponse({
      page_id: this.page_id,
      ids: this.page.find(selector)
    });
  };
  Browser.prototype.find_within = function(page_id, id, selector) {
    return this.sendResponse(this.node(page_id, id).find(selector));
  };
  Browser.prototype.text = function(page_id, id) {
    return this.sendResponse(this.node(page_id, id).text());
  };
  Browser.prototype.attribute = function(page_id, id, name) {
    return this.sendResponse(this.node(page_id, id).getAttribute(name));
  };
  Browser.prototype.value = function(page_id, id) {
    return this.sendResponse(this.node(page_id, id).value());
  };
  Browser.prototype.set = function(page_id, id, value) {
    this.node(page_id, id).set(value);
    return this.sendResponse(true);
  };
  Browser.prototype.select_file = function(page_id, id, value) {
    var element, multiple;
    element = this.node(page_id, id);
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
    return this.sendResponse(true);
  };
  Browser.prototype.select = function(page_id, id, value) {
    return this.sendResponse(this.node(page_id, id).select(value));
  };
  Browser.prototype.tag_name = function(page_id, id) {
    return this.sendResponse(this.node(page_id, id).tagName());
  };
  Browser.prototype.visible = function(page_id, id) {
    return this.sendResponse(this.node(page_id, id).isVisible());
  };
  Browser.prototype.evaluate = function(script) {
    return this.sendResponse(JSON.parse(this.page.evaluate("function() { return JSON.stringify(" + script + ") }")));
  };
  Browser.prototype.execute = function(script) {
    this.page.execute("function() { " + script + " }");
    return this.sendResponse(true);
  };
  Browser.prototype.push_frame = function(id) {
    this.page.pushFrame(id);
    return this.sendResponse(true);
  };
  Browser.prototype.pop_frame = function() {
    this.page.popFrame();
    return this.sendResponse(true);
  };
  Browser.prototype.click = function(page_id, id) {
    this.state = 'clicked';
    this.node(page_id, id).click();
    return setTimeout(__bind(function() {
      if (this.state === 'clicked') {
        this.state = 'default';
        return this.sendResponse(true);
      }
    }, this), 10);
  };
  Browser.prototype.drag = function(page_id, id, other_id) {
    this.node(page_id, id).dragTo(this.page.get(other_id));
    return this.sendResponse(true);
  };
  Browser.prototype.trigger = function(page_id, id, event) {
    this.node(page_id, id).trigger(event);
    return this.sendResponse(event);
  };
  Browser.prototype.reset = function() {
    this.resetPage();
    return this.sendResponse(true);
  };
  Browser.prototype.render = function(path, full) {
    var dimensions, document, viewport;
    dimensions = this.page.validatedDimensions();
    document = dimensions.document;
    viewport = dimensions.viewport;
    if (full) {
      this.page.setScrollPosition({
        left: 0,
        top: 0
      });
      this.page.setClipRect({
        left: 0,
        top: 0,
        width: document.width,
        height: document.height
      });
      this.page.render(path);
      this.page.setScrollPosition({
        left: dimensions.left,
        top: dimensions.top
      });
    } else {
      this.page.setClipRect({
        left: 0,
        top: 0,
        width: viewport.width,
        height: viewport.height
      });
      this.page.render(path);
    }
    return this.sendResponse(true);
  };
  Browser.prototype.resize = function(width, height) {
    this.page.setViewportSize({
      width: width,
      height: height
    });
    return this.sendResponse(true);
  };
  Browser.prototype.exit = function() {
    return phantom.exit();
  };
  Browser.prototype.noop = function() {};
  return Browser;
})();