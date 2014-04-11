Poltergeist.Browser = (function() {
  function Browser(owner, width, height) {
    this.owner = owner;
    this.width = width || 1024;
    this.height = height || 768;
    this.state = "default";
    this.pageStack = [];
    this.pageId = 0;
    this.jsErrors = true;
    this._debug = false;
    this.resetPage();
  }

  Browser.prototype.resetPage = function() {
    if (this.page != null) {
      this.page.release();
      phantom.clearCookies();
    }
    this.page = new Poltergeist.WebPage;
    this.page.setViewportSize({
      width: this.width,
      height: this.height
    });
    this.page.onLoadStarted = (function(_this) {
      return function() {
        if (_this.state === "mouse_event") {
          return _this.setState("loading");
        }
      };
    })(this);
    this.page.onNavigationRequested = (function(_this) {
      return function(url, navigation) {
        if (_this.state === "mouse_event" && navigation === "FormSubmitted") {
          return _this.setState("loading");
        }
      };
    })(this);
    this.page.onLoadFinished = (function(_this) {
      return function(status) {
        if (_this.state === "loading") {
          _this.sendResponse({
            status: status,
            position: _this.lastMouseEvent
          });
          return _this.setState("default");
        } else if (_this.state === "awaiting_frame_load") {
          _this.sendResponse(true);
          return _this.setState("default");
        }
      };
    })(this);
    this.page.onInitialized = (function(_this) {
      return function() {
        return _this.pageId += 1;
      };
    })(this);
    return this.page.onPageCreated = (function(_this) {
      return function(subPage) {
        var name;
        if (_this.state === "awaiting_sub_page") {
          name = _this.pageName;
          _this.pageName = null;
          _this.setState("default");
          return setTimeout((function() {
            return _this.pushWindow(name);
          }), 0);
        }
      };
    })(this);
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
    if (errors.length && this.jsErrors) {
      return this.owner.sendError(new Poltergeist.JavascriptError(errors));
    } else {
      return this.owner.sendResponse(response);
    }
  };

  Browser.prototype.addExtension = function(extension) {
    this.page.injectExtension(extension);
    return this.sendResponse('success');
  };

  Browser.prototype.node = function(pageId, id) {
    if (pageId === this.pageId) {
      return this.page.get(id);
    } else {
      throw new Poltergeist.ObsoleteNode;
    }
  };

  Browser.prototype.visit = function(url) {
    var prevUrl;
    this.setState("loading");
    prevUrl = this.page.source() === null ? "about:blank" : this.page.currentUrl();
    this.page.open(url);
    if (/#/.test(url) && prevUrl.split("#")[0] === url.split("#")[0]) {
      this.setState("default");
      return this.sendResponse("success");
    }
  };

  Browser.prototype.currentUrl = function() {
    return this.sendResponse(this.page.currentUrl());
  };

  Browser.prototype.statusCode = function() {
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
      pageId: this.pageId,
      ids: this.page.find(method, selector)
    });
  };

  Browser.prototype.findWithin = function(pageId, id, method, selector) {
    return this.sendResponse(this.node(pageId, id).find(method, selector));
  };

  Browser.prototype.allText = function(pageId, id) {
    return this.sendResponse(this.node(pageId, id).allText());
  };

  Browser.prototype.visibleText = function(pageId, id) {
    return this.sendResponse(this.node(pageId, id).visibleText());
  };

  Browser.prototype.deleteText = function(pageId, id) {
    return this.sendResponse(this.node(pageId, id).deleteText());
  };

  Browser.prototype.attribute = function(pageId, id, name) {
    return this.sendResponse(this.node(pageId, id).getAttribute(name));
  };

  Browser.prototype.value = function(pageId, id) {
    return this.sendResponse(this.node(pageId, id).value());
  };

  Browser.prototype.set = function(pageId, id, value) {
    this.node(pageId, id).set(value);
    return this.sendResponse(true);
  };

  Browser.prototype.selectFile = function(pageId, id, value) {
    var node;
    node = this.node(pageId, id);
    this.page.beforeUpload(node.id);
    this.page.uploadFile('[_poltergeist_selected]', value);
    this.page.afterUpload(node.id);
    return this.sendResponse(true);
  };

  Browser.prototype.select = function(pageId, id, value) {
    return this.sendResponse(this.node(pageId, id).select(value));
  };

  Browser.prototype.tagName = function(pageId, id) {
    return this.sendResponse(this.node(pageId, id).tagName());
  };

  Browser.prototype.visible = function(pageId, id) {
    return this.sendResponse(this.node(pageId, id).isVisible());
  };

  Browser.prototype.disabled = function(pageId, id) {
    return this.sendResponse(this.node(pageId, id).isDisabled());
  };

  Browser.prototype.evaluate = function(script) {
    return this.sendResponse(this.page.evaluate("function() { return " + script + " }"));
  };

  Browser.prototype.execute = function(script) {
    this.page.execute("function() { " + script + " }");
    return this.sendResponse(true);
  };

  Browser.prototype.pushFrame = function(name, timeout) {
    if (timeout == null) {
      timeout = new Date().getTime() + 2000;
    }
    if (this.page.pushFrame(name)) {
      if (this.page.currentUrl() === "about:blank") {
        return this.setState("awaiting_frame_load");
      } else {
        return this.sendResponse(true);
      }
    } else {
      if (new Date().getTime() < timeout) {
        return setTimeout(((function(_this) {
          return function() {
            return _this.pushFrame(name, timeout);
          };
        })(this)), 50);
      } else {
        return this.owner.sendError(new Poltergeist.FrameNotFound(name));
      }
    }
  };

  Browser.prototype.pages = function() {
    return this.sendResponse(this.page.pages());
  };

  Browser.prototype.popFrame = function() {
    return this.sendResponse(this.page.popFrame());
  };

  Browser.prototype.pushWindow = function(name) {
    var subPage;
    subPage = this.page.getPage(name);
    if (subPage) {
      if (subPage.currentUrl() === "about:blank") {
        return subPage.onLoadFinished = (function(_this) {
          return function() {
            subPage.onLoadFinished = null;
            return _this.pushWindow(name);
          };
        })(this);
      } else {
        this.pageStack.push(this.page);
        this.page = subPage;
        this.pageId += 1;
        return this.sendResponse(true);
      }
    } else {
      this.pageName = name;
      return this.setState("awaiting_sub_page");
    }
  };

  Browser.prototype.popWindow = function() {
    var prevPage;
    prevPage = this.pageStack.pop();
    if (prevPage) {
      this.page = prevPage;
    }
    return this.sendResponse(true);
  };

  Browser.prototype.mouseEvent = function(pageId, id, name) {
    var node;
    node = this.node(pageId, id);
    this.setState("mouse_event");
    this.lastMouseEvent = node.mouseEvent(name);
    return setTimeout((function(_this) {
      return function() {
        if (_this.state !== "loading") {
          _this.setState("default");
          return _this.sendResponse(_this.lastMouseEvent);
        }
      };
    })(this), 5);
  };

  Browser.prototype.click = function(pageId, id) {
    return this.mouseEvent(pageId, id, "click");
  };

  Browser.prototype.doubleClick = function(pageId, id) {
    return this.mouseEvent(pageId, id, "doubleclick");
  };

  Browser.prototype.hover = function(pageId, id) {
    return this.mouseEvent(pageId, id, "mousemove");
  };

  Browser.prototype.clickCoordinates = function(x, y) {
    this.page.sendEvent('click', x, y);
    return this.sendResponse({
      click: {
        x: x,
        y: y
      }
    });
  };

  Browser.prototype.drag = function(pageId, id, otherId) {
    this.node(pageId, id).dragTo(this.node(pageId, otherId));
    return this.sendResponse(true);
  };

  Browser.prototype.trigger = function(pageId, id, event) {
    this.node(pageId, id).trigger(event);
    return this.sendResponse(event);
  };

  Browser.prototype.equals = function(pageId, id, otherId) {
    return this.sendResponse(this.node(pageId, id).isEqual(this.node(pageId, otherId)));
  };

  Browser.prototype.reset = function() {
    this.resetPage();
    return this.sendResponse(true);
  };

  Browser.prototype.scrollTo = function(left, top) {
    this.page.setScrollPosition({
      left: left,
      top: top
    });
    return this.sendResponse(true);
  };

  Browser.prototype.sendKeys = function(pageId, id, keys) {
    var key, sequence, _i, _len;
    this.node(pageId, id).mouseEvent("click");
    for (_i = 0, _len = keys.length; _i < _len; _i++) {
      sequence = keys[_i];
      key = sequence.key != null ? this.page["native"].event.key[sequence.key] : sequence;
      this.page.sendEvent("keypress", key);
    }
    return this.sendResponse(true);
  };

  Browser.prototype.renderBase64 = function(format, full, selector) {
    var encodedImage;
    if (selector == null) {
      selector = null;
    }
    this.setClipRect(full, selector);
    encodedImage = this.page.renderBase64(format);
    return this.sendResponse(encodedImage);
  };

  Browser.prototype.render = function(path, full, selector) {
    var dimensions;
    if (selector == null) {
      selector = null;
    }
    dimensions = this.setClipRect(full, selector);
    this.page.setScrollPosition({
      left: 0,
      top: 0
    });
    this.page.render(path);
    this.page.setScrollPosition({
      left: dimensions.left,
      top: dimensions.top
    });
    return this.sendResponse(true);
  };

  Browser.prototype.setClipRect = function(full, selector) {
    var dimensions, document, rect, viewport, _ref;
    dimensions = this.page.validatedDimensions();
    _ref = [dimensions.document, dimensions.viewport], document = _ref[0], viewport = _ref[1];
    rect = full ? {
      left: 0,
      top: 0,
      width: document.width,
      height: document.height
    } : selector != null ? this.page.elementBounds(selector) : {
      left: 0,
      top: 0,
      width: viewport.width,
      height: viewport.height
    };
    this.page.setClipRect(rect);
    return dimensions;
  };

  Browser.prototype.setPaperSize = function(size) {
    this.page.setPaperSize(size);
    return this.sendResponse(true);
  };

  Browser.prototype.setZoomFactor = function(zoomFactor) {
    this.page.setZoomFactor(zoomFactor);
    return this.sendResponse(true);
  };

  Browser.prototype.resize = function(width, height) {
    this.page.setViewportSize({
      width: width,
      height: height
    });
    return this.sendResponse(true);
  };

  Browser.prototype.networkTraffic = function() {
    return this.sendResponse(this.page.networkTraffic());
  };

  Browser.prototype.clearNetworkTraffic = function() {
    this.page.clearNetworkTraffic();
    return this.sendResponse(true);
  };

  Browser.prototype.getHeaders = function() {
    return this.sendResponse(this.page.getCustomHeaders());
  };

  Browser.prototype.setHeaders = function(headers) {
    if (headers['User-Agent']) {
      this.page.setUserAgent(headers['User-Agent']);
    }
    this.page.setCustomHeaders(headers);
    return this.sendResponse(true);
  };

  Browser.prototype.addHeaders = function(headers) {
    var allHeaders, name, value;
    allHeaders = this.page.getCustomHeaders();
    for (name in headers) {
      value = headers[name];
      allHeaders[name] = value;
    }
    return this.setHeaders(allHeaders);
  };

  Browser.prototype.addHeader = function(header, permanent) {
    if (!permanent) {
      this.page.addTempHeader(header);
    }
    return this.addHeaders(header);
  };

  Browser.prototype.responseHeaders = function() {
    return this.sendResponse(this.page.responseHeaders());
  };

  Browser.prototype.cookies = function() {
    return this.sendResponse(this.page.cookies());
  };

  Browser.prototype.setCookie = function(cookie) {
    phantom.addCookie(cookie);
    return this.sendResponse(true);
  };

  Browser.prototype.removeCookie = function(name) {
    this.page.deleteCookie(name);
    return this.sendResponse(true);
  };

  Browser.prototype.cookiesEnabled = function(flag) {
    phantom.cookiesEnabled = flag;
    return this.sendResponse(true);
  };

  Browser.prototype.setHttpAuth = function(user, password) {
    this.page.setHttpAuth(user, password);
    return this.sendResponse(true);
  };

  Browser.prototype.setJsErrors = function(value) {
    this.jsErrors = value;
    return this.sendResponse(true);
  };

  Browser.prototype.setDebug = function(value) {
    this._debug = value;
    return this.sendResponse(true);
  };

  Browser.prototype.exit = function() {
    return phantom.exit();
  };

  Browser.prototype.noop = function() {};

  Browser.prototype.browserError = function() {
    throw new Error("zomg");
  };

  Browser.prototype.goBack = function() {
    if (this.page.canGoBack) {
      this.page.goBack();
    }
    return this.sendResponse(true);
  };

  Browser.prototype.goForward = function() {
    if (this.page.canGoForward) {
      this.page.goForward();
    }
    return this.sendResponse(true);
  };

  return Browser;

})();
