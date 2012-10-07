
Poltergeist.Browser = (function() {

  function Browser(owner, width, height) {
    this.owner = owner;
    this.width = width || 1024;
    this.height = height || 768;
    this.state = 'default';
    this.page_stack = [];
    this.page_id = 0;
    this.resetPage();
  }

  Browser.prototype.resetPage = function() {
    var _this = this;
    if (this.page != null) {
      this.page.release();
      phantom.clearCookies();
    }
    this.page = new Poltergeist.WebPage;
    this.page.setViewportSize({
      width: this.width,
      height: this.height
    });
    this.page.onLoadStarted = function() {
      if (_this.state === 'clicked') {
        return _this.state = 'loading';
      }
    };
    this.page.onNavigationRequested = function(url, navigation) {
      if (_this.state === 'clicked' && navigation === 'FormSubmitted') {
        return _this.state = 'loading';
      }
    };
    this.page.onLoadFinished = function(status) {
      if (_this.state === 'loading') {
        _this.sendResponse({
          status: status,
          click: _this.last_click
        });
        return _this.state = 'default';
      } else if (_this.state === 'awaiting_frame_load') {
        _this.sendResponse(true);
        return _this.state = 'default';
      }
    };
    this.page.onInitialized = function() {
      return _this.page_id += 1;
    };
    return this.page.onPageCreated = function(sub_page) {
      var name;
      if (_this.state === 'awaiting_sub_page') {
        name = _this.page_name;
        _this.state = 'default';
        _this.page_name = null;
        return setTimeout((function() {
          return _this.push_window(name);
        }), 0);
      }
    };
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
    var prev_url;
    this.state = 'loading';
    prev_url = this.page.currentUrl();
    this.page.open(url);
    if (/#/.test(url) && prev_url.split('#')[0] === url.split('#')[0]) {
      this.state = 'default';
      return this.sendResponse('success');
    }
  };

  Browser.prototype.current_url = function() {
    return this.sendResponse(this.page.currentUrl());
  };

  Browser.prototype.status_code = function() {
    return this.sendResponse(this.page.statusCode());
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
    var node;
    node = this.node(page_id, id);
    node.setAttribute('_poltergeist_selected', '');
    this.page.uploadFile('[_poltergeist_selected]', value);
    node.removeAttribute('_poltergeist_selected');
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
    return this.sendResponse(this.page.evaluate("function() { return " + script + " }"));
  };

  Browser.prototype.execute = function(script) {
    this.page.execute("function() { " + script + " }");
    return this.sendResponse(true);
  };

  Browser.prototype.push_frame = function(name) {
    var _this = this;
    if (this.page.pushFrame(name)) {
      if (this.page.currentUrl() === 'about:blank') {
        return this.state = 'awaiting_frame_load';
      } else {
        return this.sendResponse(true);
      }
    } else {
      return setTimeout((function() {
        return _this.push_frame(name);
      }), 50);
    }
  };

  Browser.prototype.pop_frame = function() {
    return this.sendResponse(this.page.popFrame());
  };

  Browser.prototype.push_window = function(name) {
    var sub_page,
      _this = this;
    sub_page = this.page.getPage(name);
    if (sub_page) {
      if (sub_page.currentUrl() === 'about:blank') {
        return sub_page.onLoadFinished = function() {
          sub_page.onLoadFinished = null;
          return _this.push_window(name);
        };
      } else {
        this.page_stack.push(this.page);
        this.page = sub_page;
        this.page_id += 1;
        return this.sendResponse(true);
      }
    } else {
      this.page_name = name;
      return this.state = 'awaiting_sub_page';
    }
  };

  Browser.prototype.pop_window = function() {
    var prev_page;
    prev_page = this.page_stack.pop();
    if (prev_page) {
      this.page = prev_page;
    }
    return this.sendResponse(true);
  };

  Browser.prototype.click = function(page_id, id) {
    var node,
      _this = this;
    node = this.node(page_id, id);
    this.state = 'clicked';
    this.last_click = node.click();
    return setTimeout(function() {
      if (_this.state !== 'loading') {
        _this.state = 'default';
        return _this.sendResponse(_this.last_click);
      }
    }, 5);
  };

  Browser.prototype.drag = function(page_id, id, other_id) {
    this.node(page_id, id).dragTo(this.node(page_id, other_id));
    return this.sendResponse(true);
  };

  Browser.prototype.trigger = function(page_id, id, event) {
    this.node(page_id, id).trigger(event);
    return this.sendResponse(event);
  };

  Browser.prototype.equals = function(page_id, id, other_id) {
    return this.sendResponse(this.node(page_id, id).isEqual(this.node(page_id, other_id)));
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

  Browser.prototype.network_traffic = function() {
    return this.sendResponse(this.page.networkTraffic());
  };

  Browser.prototype.set_headers = function(headers) {
    if (headers['User-Agent']) {
      this.page.setUserAgent(headers['User-Agent']);
    }
    this.page.setCustomHeaders(headers);
    return this.sendResponse(true);
  };

  Browser.prototype.response_headers = function() {
    return this.sendResponse(this.page.responseHeaders());
  };

  Browser.prototype.cookies = function() {
    return this.sendResponse(this.page.cookies());
  };

  Browser.prototype.set_cookie = function(cookie) {
    phantom.addCookie(cookie);
    return this.sendResponse(true);
  };

  Browser.prototype.remove_cookie = function(name) {
    this.page.deleteCookie(name);
    return this.sendResponse(true);
  };

  Browser.prototype.exit = function() {
    return phantom.exit();
  };

  Browser.prototype.noop = function() {};

  Browser.prototype.browser_error = function() {
    throw new Error('zomg');
  };

  return Browser;

})();
