var __slice = [].slice,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Poltergeist.WebPage = (function() {
  var command, delegate, _fn, _fn1, _i, _j, _len, _len1, _ref, _ref1,
    _this = this;

  WebPage.CALLBACKS = ['onAlert', 'onConsoleMessage', 'onLoadFinished', 'onInitialized', 'onLoadStarted', 'onResourceRequested', 'onResourceReceived', 'onError', 'onNavigationRequested', 'onUrlChanged', 'onPageCreated', 'onClosing'];

  WebPage.DELEGATES = ['open', 'sendEvent', 'uploadFile', 'release', 'render', 'renderBase64', 'goBack', 'goForward'];

  WebPage.COMMANDS = ['currentUrl', 'find', 'nodeCall', 'documentSize', 'beforeUpload', 'afterUpload', 'clearLocalStorage'];

  WebPage.EXTENSIONS = [];

  function WebPage(_native) {
    var callback, _i, _len, _ref;
    this._native = _native;
    this._native || (this._native = require('webpage').create());
    this.id = 0;
    this.source = null;
    this.closed = false;
    this.state = 'default';
    this.urlBlacklist = [];
    this.frames = [];
    this.errors = [];
    this._networkTraffic = {};
    this._tempHeaders = {};
    this._blockedUrls = [];
    _ref = WebPage.CALLBACKS;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      callback = _ref[_i];
      this.bindCallback(callback);
    }
  }

  _ref = WebPage.COMMANDS;
  _fn = function(command) {
    return WebPage.prototype[command] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.runCommand(command, args);
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    command = _ref[_i];
    _fn(command);
  }

  _ref1 = WebPage.DELEGATES;
  _fn1 = function(delegate) {
    return WebPage.prototype[delegate] = function() {
      return this._native[delegate].apply(this._native, arguments);
    };
  };
  for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
    delegate = _ref1[_j];
    _fn1(delegate);
  }

  WebPage.prototype.onInitializedNative = function() {
    this.id += 1;
    this.source = null;
    this.injectAgent();
    this.removeTempHeaders();
    return this.setScrollPosition({
      left: 0,
      top: 0
    });
  };

  WebPage.prototype.onClosingNative = function() {
    this.handle = null;
    return this.closed = true;
  };

  WebPage.prototype.onConsoleMessageNative = function(message) {
    if (message === '__DOMContentLoaded') {
      this.source = this._native.content;
      return false;
    } else {
      return console.log(message);
    }
  };

  WebPage.prototype.onLoadStartedNative = function() {
    this.state = 'loading';
    return this.requestId = this.lastRequestId;
  };

  WebPage.prototype.onLoadFinishedNative = function(status) {
    this.status = status;
    this.state = 'default';
    return this.source || (this.source = this._native.content);
  };

  WebPage.prototype.onErrorNative = function(message, stack) {
    var stackString;
    stackString = message;
    stack.forEach(function(frame) {
      stackString += "\n";
      stackString += "    at " + frame.file + ":" + frame.line;
      if (frame["function"] && frame["function"] !== '') {
        return stackString += " in " + frame["function"];
      }
    });
    return this.errors.push({
      message: message,
      stack: stackString
    });
  };

  WebPage.prototype.onResourceRequestedNative = function(request, net) {
    var abort, _ref2;
    abort = this.urlBlacklist.some(function(blacklisted_url) {
      return request.url.indexOf(blacklisted_url) !== -1;
    });
    if (abort) {
      if (_ref2 = request.url, __indexOf.call(this._blockedUrls, _ref2) < 0) {
        this._blockedUrls.push(request.url);
      }
      return net.abort();
    } else {
      this.lastRequestId = request.id;
      if (request.url === this.redirectURL) {
        this.redirectURL = null;
        this.requestId = request.id;
      }
      return this._networkTraffic[request.id] = {
        request: request,
        responseParts: []
      };
    }
  };

  WebPage.prototype.onResourceReceivedNative = function(response) {
    var _ref2;
    if ((_ref2 = this._networkTraffic[response.id]) != null) {
      _ref2.responseParts.push(response);
    }
    if (this.requestId === response.id) {
      if (response.redirectURL) {
        return this.redirectURL = response.redirectURL;
      } else {
        this.statusCode = response.status;
        return this._responseHeaders = response.headers;
      }
    }
  };

  WebPage.prototype.injectAgent = function() {
    var extension, _k, _len2, _ref2, _results;
    if (this["native"]().evaluate(function() {
      return typeof __poltergeist;
    }) === "undefined") {
      this["native"]().injectJs("" + phantom.libraryPath + "/agent.js");
      _ref2 = WebPage.EXTENSIONS;
      _results = [];
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        extension = _ref2[_k];
        _results.push(this["native"]().injectJs(extension));
      }
      return _results;
    }
  };

  WebPage.prototype.injectExtension = function(file) {
    WebPage.EXTENSIONS.push(file);
    return this["native"]().injectJs(file);
  };

  WebPage.prototype["native"] = function() {
    if (this.closed) {
      throw new Poltergeist.NoSuchWindowError;
    } else {
      return this._native;
    }
  };

  WebPage.prototype.windowName = function() {
    return this["native"]().windowName;
  };

  WebPage.prototype.keyCode = function(name) {
    return this["native"]().event.key[name];
  };

  WebPage.prototype.waitState = function(state, callback) {
    var _this = this;
    if (this.state === state) {
      return callback.call();
    } else {
      return setTimeout((function() {
        return _this.waitState(state, callback);
      }), 100);
    }
  };

  WebPage.prototype.setHttpAuth = function(user, password) {
    this["native"]().settings.userName = user;
    return this["native"]().settings.password = password;
  };

  WebPage.prototype.networkTraffic = function() {
    return this._networkTraffic;
  };

  WebPage.prototype.clearNetworkTraffic = function() {
    return this._networkTraffic = {};
  };

  WebPage.prototype.blockedUrls = function() {
    return this._blockedUrls;
  };

  WebPage.prototype.clearBlockedUrls = function() {
    return this._blockedUrls = [];
  };

  WebPage.prototype.content = function() {
    return this["native"]().frameContent;
  };

  WebPage.prototype.title = function() {
    return this["native"]().frameTitle;
  };

  WebPage.prototype.frameUrl = function(frameName) {
    var query;
    query = function(frameName) {
      var _ref2;
      return (_ref2 = document.querySelector("iframe[name='" + frameName + "']")) != null ? _ref2.src : void 0;
    };
    return this.evaluate(query, frameName);
  };

  WebPage.prototype.clearErrors = function() {
    return this.errors = [];
  };

  WebPage.prototype.responseHeaders = function() {
    var headers;
    headers = {};
    this._responseHeaders.forEach(function(item) {
      return headers[item.name] = item.value;
    });
    return headers;
  };

  WebPage.prototype.cookies = function() {
    return this["native"]().cookies;
  };

  WebPage.prototype.deleteCookie = function(name) {
    return this["native"]().deleteCookie(name);
  };

  WebPage.prototype.viewportSize = function() {
    return this["native"]().viewportSize;
  };

  WebPage.prototype.setViewportSize = function(size) {
    return this["native"]().viewportSize = size;
  };

  WebPage.prototype.setZoomFactor = function(zoom_factor) {
    return this["native"]().zoomFactor = zoom_factor;
  };

  WebPage.prototype.setPaperSize = function(size) {
    return this["native"]().paperSize = size;
  };

  WebPage.prototype.scrollPosition = function() {
    return this["native"]().scrollPosition;
  };

  WebPage.prototype.setScrollPosition = function(pos) {
    return this["native"]().scrollPosition = pos;
  };

  WebPage.prototype.clipRect = function() {
    return this["native"]().clipRect;
  };

  WebPage.prototype.setClipRect = function(rect) {
    return this["native"]().clipRect = rect;
  };

  WebPage.prototype.elementBounds = function(selector) {
    return this["native"]().evaluate(function(selector) {
      return document.querySelector(selector).getBoundingClientRect();
    }, selector);
  };

  WebPage.prototype.setUserAgent = function(userAgent) {
    return this["native"]().settings.userAgent = userAgent;
  };

  WebPage.prototype.getCustomHeaders = function() {
    return this["native"]().customHeaders;
  };

  WebPage.prototype.setCustomHeaders = function(headers) {
    return this["native"]().customHeaders = headers;
  };

  WebPage.prototype.addTempHeader = function(header) {
    var name, value, _results;
    _results = [];
    for (name in header) {
      value = header[name];
      _results.push(this._tempHeaders[name] = value);
    }
    return _results;
  };

  WebPage.prototype.removeTempHeaders = function() {
    var allHeaders, name, value, _ref2;
    allHeaders = this.getCustomHeaders();
    _ref2 = this._tempHeaders;
    for (name in _ref2) {
      value = _ref2[name];
      delete allHeaders[name];
    }
    return this.setCustomHeaders(allHeaders);
  };

  WebPage.prototype.pushFrame = function(name) {
    if (this["native"]().switchToFrame(name)) {
      this.frames.push(name);
      return true;
    } else {
      return false;
    }
  };

  WebPage.prototype.popFrame = function() {
    this.frames.pop();
    return this["native"]().switchToParentFrame();
  };

  WebPage.prototype.dimensions = function() {
    var scroll, viewport;
    scroll = this.scrollPosition();
    viewport = this.viewportSize();
    return {
      top: scroll.top,
      bottom: scroll.top + viewport.height,
      left: scroll.left,
      right: scroll.left + viewport.width,
      viewport: viewport,
      document: this.documentSize()
    };
  };

  WebPage.prototype.validatedDimensions = function() {
    var dimensions, document;
    dimensions = this.dimensions();
    document = dimensions.document;
    if (dimensions.right > document.width) {
      dimensions.left = Math.max(0, dimensions.left - (dimensions.right - document.width));
      dimensions.right = document.width;
    }
    if (dimensions.bottom > document.height) {
      dimensions.top = Math.max(0, dimensions.top - (dimensions.bottom - document.height));
      dimensions.bottom = document.height;
    }
    this.setScrollPosition({
      left: dimensions.left,
      top: dimensions.top
    });
    return dimensions;
  };

  WebPage.prototype.get = function(id) {
    return new Poltergeist.Node(this, id);
  };

  WebPage.prototype.mouseEvent = function(name, x, y, button) {
    if (button == null) {
      button = 'left';
    }
    this.sendEvent('mousemove', x, y);
    return this.sendEvent(name, x, y, button);
  };

  WebPage.prototype.evaluate = function() {
    var args, fn;
    fn = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    this.injectAgent();
    return JSON.parse(this.sanitize(this["native"]().evaluate("function() { return PoltergeistAgent.stringify(" + (this.stringifyCall(fn, args)) + ") }")));
  };

  WebPage.prototype.sanitize = function(potential_string) {
    if (typeof potential_string === "string") {
      return potential_string.replace("\n", "\\n").replace("\r", "\\r");
    } else {
      return potential_string;
    }
  };

  WebPage.prototype.execute = function() {
    var args, fn;
    fn = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return this["native"]().evaluate("function() { " + (this.stringifyCall(fn, args)) + " }");
  };

  WebPage.prototype.stringifyCall = function(fn, args) {
    if (args.length === 0) {
      return "(" + (fn.toString()) + ")()";
    } else {
      return "(" + (fn.toString()) + ").apply(this, JSON.parse(" + (JSON.stringify(JSON.stringify(args))) + "))";
    }
  };

  WebPage.prototype.bindCallback = function(name) {
    var that;
    that = this;
    return this["native"]()[name] = function() {
      var result;
      if (that[name + 'Native'] != null) {
        result = that[name + 'Native'].apply(that, arguments);
      }
      if (result !== false && (that[name] != null)) {
        return that[name].apply(that, arguments);
      }
    };
  };

  WebPage.prototype.runCommand = function(name, args) {
    var method, result, selector;
    result = this.evaluate(function(name, args) {
      return __poltergeist.externalCall(name, args);
    }, name, args);
    if (result !== null) {
      if (result.error != null) {
        switch (result.error.message) {
          case 'PoltergeistAgent.ObsoleteNode':
            throw new Poltergeist.ObsoleteNode;
            break;
          case 'PoltergeistAgent.InvalidSelector':
            method = args[0], selector = args[1];
            throw new Poltergeist.InvalidSelector(method, selector);
            break;
          default:
            throw new Poltergeist.BrowserError(result.error.message, result.error.stack);
        }
      } else {
        return result.value;
      }
    }
  };

  WebPage.prototype.canGoBack = function() {
    return this["native"]().canGoBack;
  };

  WebPage.prototype.canGoForward = function() {
    return this["native"]().canGoForward;
  };

  return WebPage;

}).call(this);
