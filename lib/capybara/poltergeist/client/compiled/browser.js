Poltergeist.Browser = (function() {
  function Browser(owner, width, height) {
    this.owner = owner;
    this.width = width || 1024;
    this.height = height || 768;
    this.state = 'default';
    this.page_stack = [];
    this.page_id = 0;
    this.js_errors = true;
    this._debug = false;
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
      if (_this.state === 'mouse_event') {
        return _this.setState('loading');
      }
    };
    this.page.onNavigationRequested = function(url, navigation) {
      if (_this.state === 'mouse_event' && navigation === 'FormSubmitted') {
        return _this.setState('loading');
      }
    };
    this.page.onLoadFinished = function(status) {
      if (_this.state === 'loading') {
        _this.sendResponse({
          status: status,
          position: _this.last_mouse_event
        });
        return _this.setState('default');
      } else if (_this.state === 'awaiting_frame_load') {
        _this.sendResponse(true);
        return _this.setState('default');
      }
    };
    this.page.onInitialized = function() {
      return _this.page_id += 1;
    };
    return this.page.onPageCreated = function(sub_page) {
      var name;

      if (_this.state === 'awaiting_sub_page') {
        name = _this.page_name;
        _this.page_name = null;
        _this.setState('default');
        return setTimeout((function() {
          return _this.push_window(name);
        }), 0);
      }
    };
  };

  Browser.prototype.runCommand = function(name, args) {
    this.setState("default");
    return this[name].apply(this, args);
  };

  Browser.prototype.debug = function(message) {
    if (this._debug) {
      return console.log("poltergeist [" + (new Date().getTime()) + "] " + message);
    }
  };

  Browser.prototype.setState = function(state) {
    if (this.state === state) {
      return;
    }
    this.debug("state " + this.state + " -> " + state);
    return this.state = state;
  };

  Browser.prototype.sendResponse = function(response) {
    var errors;

    errors = this.page.errors();
    this.page.clearErrors();
    if (errors.length > 0 && this.js_errors) {
      return this.owner.sendError(new Poltergeist.JavascriptError(errors));
    } else {
      return this.owner.sendResponse(response);
    }
  };

  Browser.prototype.add_extension = function(extension) {
    this.page.injectExtension(extension);
    return this.sendResponse('success');
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

    this.setState('loading');
    prev_url = this.page.currentUrl();
    this.page.open(url);
    if (/#/.test(url) && prev_url.split('#')[0] === url.split('#')[0]) {
      this.setState('default');
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

  Browser.prototype.title = function() {
    return this.sendResponse(this.page.title());
  };

  Browser.prototype.find = function(method, selector) {
    return this.sendResponse({
      page_id: this.page_id,
      ids: this.page.find(method, selector)
    });
  };

  Browser.prototype.find_within = function(page_id, id, method, selector) {
    return this.sendResponse(this.node(page_id, id).find(method, selector));
  };

  Browser.prototype.all_text = function(page_id, id) {
    return this.sendResponse(this.node(page_id, id).allText());
  };

  Browser.prototype.visible_text = function(page_id, id) {
    return this.sendResponse(this.node(page_id, id).visibleText());
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
    this.page.beforeUpload(node.id);
    this.page.uploadFile('[_poltergeist_selected]', value);
    this.page.afterUpload(node.id);
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

  Browser.prototype.disabled = function(page_id, id) {
    return this.sendResponse(this.node(page_id, id).isDisabled());
  };

  Browser.prototype.evaluate = function(script) {
    return this.sendResponse(this.page.evaluate("function() { return " + script + " }"));
  };

  Browser.prototype.execute = function(script) {
    this.page.execute("function() { " + script + " }");
    return this.sendResponse(true);
  };

  Browser.prototype.push_frame = function(name, timeout) {
    var _this = this;

    if (timeout == null) {
      timeout = new Date().getTime() + 2000;
    }
    if (this.page.pushFrame(name)) {
      if (this.page.currentUrl() === 'about:blank') {
        return this.setState('awaiting_frame_load');
      } else {
        return this.sendResponse(true);
      }
    } else {
      if (new Date().getTime() < timeout) {
        return setTimeout((function() {
          return _this.push_frame(name, timeout);
        }), 50);
      } else {
        return this.owner.sendError(new Poltergeist.FrameNotFound(name));
      }
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
      return this.setState('awaiting_sub_page');
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

  Browser.prototype.mouse_event = function(page_id, id, name) {
    var node,
      _this = this;

    node = this.node(page_id, id);
    this.setState('mouse_event');
    this.last_mouse_event = node.mouseEvent(name);
    return setTimeout(function() {
      if (_this.state !== 'loading') {
        _this.setState('default');
        return _this.sendResponse(_this.last_mouse_event);
      }
    }, 5);
  };

  Browser.prototype.click = function(page_id, id) {
    return this.mouse_event(page_id, id, 'click');
  };

  Browser.prototype.double_click = function(page_id, id) {
    return this.mouse_event(page_id, id, 'doubleclick');
  };

  Browser.prototype.hover = function(page_id, id) {
    return this.mouse_event(page_id, id, 'mousemove');
  };

  Browser.prototype.click_coordinates = function(x, y) {
    this.page.sendEvent('click', x, y);
    return this.sendResponse({
      click: {
        x: x,
        y: y
      }
    });
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

  Browser.prototype.cookies_enabled = function(flag) {
    phantom.cookiesEnabled = flag;
    return this.sendResponse(true);
  };

  Browser.prototype.set_js_errors = function(value) {
    this.js_errors = value;
    return this.sendResponse(true);
  };

  Browser.prototype.set_debug = function(value) {
    this._debug = value;
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
