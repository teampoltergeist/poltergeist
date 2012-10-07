var __slice = [].slice;

Poltergeist.WebPage = (function() {
  var command, delegate, _fn, _fn1, _i, _j, _len, _len1, _ref, _ref1,
    _this = this;

  WebPage.CALLBACKS = ['onAlert', 'onConsoleMessage', 'onLoadFinished', 'onInitialized', 'onLoadStarted', 'onResourceRequested', 'onResourceReceived', 'onError', 'onNavigationRequested', 'onUrlChanged', 'onPageCreated'];

  WebPage.DELEGATES = ['open', 'sendEvent', 'uploadFile', 'release', 'render'];

  WebPage.COMMANDS = ['currentUrl', 'find', 'nodeCall', 'documentSize'];

  function WebPage(_native) {
    var callback, _i, _len, _ref;
    this["native"] = _native;
    this["native"] || (this["native"] = require('webpage').create());
    this._source = "";
    this._errors = [];
    this._networkTraffic = {};
    this.frames = [];
    this.sub_pages = {};
    _ref = WebPage.CALLBACKS;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      callback = _ref[_i];
      this.bindCallback(callback);
    }
    this.injectAgent();
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
      return this["native"][delegate].apply(this["native"], arguments);
    };
  };
  for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
    delegate = _ref1[_j];
    _fn1(delegate);
  }

  WebPage.prototype.onInitializedNative = function() {
    this._source = null;
    this.injectAgent();
    return this.setScrollPosition({
      left: 0,
      top: 0
    });
  };

  WebPage.prototype.injectAgent = function() {
    if (this["native"].evaluate(function() {
      return typeof __poltergeist;
    }) === "undefined") {
      return this["native"].injectJs("" + phantom.libraryPath + "/agent.js");
    }
  };

  WebPage.prototype.onConsoleMessageNative = function(message) {
    if (message === '__DOMContentLoaded') {
      this._source = this["native"].content;
      return false;
    }
  };

  WebPage.prototype.onLoadStartedNative = function() {
    return this.requestId = this.lastRequestId;
  };

  WebPage.prototype.onLoadFinishedNative = function() {
    return this._source || (this._source = this["native"].content);
  };

  WebPage.prototype.onConsoleMessage = function(message) {
    return console.log(message);
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
    return this._errors.push({
      message: message,
      stack: stackString
    });
  };

  WebPage.prototype.onResourceRequestedNative = function(request) {
    this.lastRequestId = request.id;
    if (request.url === this.redirectURL) {
      this.redirectURL = null;
      this.requestId = request.id;
    }
    return this._networkTraffic[request.id] = {
      request: request,
      responseParts: []
    };
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
        this._statusCode = response.status;
        return this._responseHeaders = response.headers;
      }
    }
  };

  WebPage.prototype.networkTraffic = function() {
    return this._networkTraffic;
  };

  WebPage.prototype.content = function() {
    return this["native"].frameContent;
  };

  WebPage.prototype.source = function() {
    return this._source;
  };

  WebPage.prototype.errors = function() {
    return this._errors;
  };

  WebPage.prototype.clearErrors = function() {
    return this._errors = [];
  };

  WebPage.prototype.statusCode = function() {
    return this._statusCode;
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
    return this["native"].cookies;
  };

  WebPage.prototype.deleteCookie = function(name) {
    return this["native"].deleteCookie(name);
  };

  WebPage.prototype.viewportSize = function() {
    return this["native"].viewportSize;
  };

  WebPage.prototype.setViewportSize = function(size) {
    return this["native"].viewportSize = size;
  };

  WebPage.prototype.scrollPosition = function() {
    return this["native"].scrollPosition;
  };

  WebPage.prototype.setScrollPosition = function(pos) {
    return this["native"].scrollPosition = pos;
  };

  WebPage.prototype.clipRect = function() {
    return this["native"].clipRect;
  };

  WebPage.prototype.setClipRect = function(rect) {
    return this["native"].clipRect = rect;
  };

  WebPage.prototype.setUserAgent = function(userAgent) {
    return this["native"].settings.userAgent = userAgent;
  };

  WebPage.prototype.setCustomHeaders = function(headers) {
    return this["native"].customHeaders = headers;
  };

  WebPage.prototype.pushFrame = function(name) {
    var res;
    this.frames.push(name);
    res = this["native"].switchToFrame(name);
    this.injectAgent();
    return res;
  };

  WebPage.prototype.popFrame = function() {
    this.frames.pop();
    if (this.frames.length === 0) {
      return this["native"].switchToMainFrame();
    } else {
      return this["native"].switchToFrame(this.frames[this.frames.length - 1]);
    }
  };

  WebPage.prototype.getPage = function(name) {
    var page;
    if (this.sub_pages[name]) {
      return this.sub_pages[name];
    } else {
      page = this["native"].getPage(name);
      if (page) {
        return this.sub_pages[name] = new Poltergeist.WebPage(page);
      }
    }
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

  WebPage.prototype.mouseEvent = function(name, x, y) {
    this.sendEvent('mousemove', x, y);
    return this.sendEvent(name, x, y);
  };

  WebPage.prototype.evaluate = function() {
    var args, fn;
    fn = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return JSON.parse(this["native"].evaluate("function() { return PoltergeistAgent.stringify(" + (this.stringifyCall(fn, args)) + ") }"));
  };

  WebPage.prototype.execute = function() {
    var args, fn;
    fn = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return this["native"].evaluate("function() { " + (this.stringifyCall(fn, args)) + " }");
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
    return this["native"][name] = function() {
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
    var result;
    result = this.evaluate(function(name, args) {
      return __poltergeist.externalCall(name, args);
    }, name, args);
    if (result.error != null) {
      if (result.error.message === 'PoltergeistAgent.ObsoleteNode') {
        throw new Poltergeist.ObsoleteNode;
      } else {
        throw new Poltergeist.JavascriptError([result.error]);
      }
    } else {
      return result.value;
    }
  };

  return WebPage;

}).call(this);
