var __slice = [].slice;

Poltergeist.WebPage = (function() {
  var command, delegate, _fn, _fn1, _i, _j, _len, _len1, _ref, _ref1,
    _this = this;

  WebPage.CALLBACKS = ['onAlert', 'onConsoleMessage', 'onLoadFinished', 'onInitialized', 'onLoadStarted', 'onResourceRequested', 'onResourceReceived', 'onError'];

  WebPage.DELEGATES = ['sendEvent', 'uploadFile', 'release', 'render'];

  WebPage.COMMANDS = ['currentUrl', 'find', 'nodeCall', 'pushFrame', 'popFrame', 'documentSize'];

  function WebPage(width, height) {
    var callback, _i, _len, _ref;
    this["native"] = require('webpage').create();
    this._source = "";
    this._errors = [];
    this.setViewportSize({
      width: width,
      height: height
    });
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
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this["native"][delegate].apply(this["native"], args);
    };
  };
  for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
    delegate = _ref1[_j];
    _fn1(delegate);
  }

  WebPage.prototype.open = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    this._url = args[0];
    return this["native"].open.apply(this["native"], args);
  };

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
      this["native"].injectJs("" + phantom.libraryPath + "/agent.js");
      return this.nodes = {};
    }
  };

  WebPage.prototype.onConsoleMessageNative = function(message) {
    if (message === '__DOMContentLoaded') {
      this._source = this["native"].content;
      return false;
    }
  };

  WebPage.prototype.onLoadFinishedNative = function() {
    return this._source || (this._source = this["native"].content);
  };

  WebPage.prototype.onConsoleMessage = function(message, line, file) {
    if (!(this._errors.length && this._errors[this._errors.length - 1].message === message)) {
      return console.log(message);
    }
  };

  WebPage.prototype.onErrorNative = function(message, stack) {
    return this._errors.push({
      message: message,
      stack: stack
    });
  };

  WebPage.prototype.onResourceReceivedNative = function(request) {
    if (this._url === request.url) {
      if (request.redirectURL) {
        return this._url = request.redirectURL;
      } else {
        return this._statusCode = request.status;
      }
    }
  };

  WebPage.prototype.content = function() {
    return this["native"].content;
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
    var dimensions, document, orig_left, orig_top;
    dimensions = this.dimensions();
    document = dimensions.document;
    orig_left = dimensions.left;
    orig_top = dimensions.top;
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
    var _base;
    return (_base = this.nodes)[id] || (_base[id] = new Poltergeist.Node(this, id));
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
      var args, result;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (that[name + 'Native'] != null) {
        result = that[name + 'Native'].apply(that, args);
      }
      if (result !== false && (that[name] != null)) {
        return that[name].apply(that, args);
      }
    };
  };

  WebPage.prototype.runCommand = function(name, args) {
    var result;
    result = this.evaluate(function(name, args) {
      return __poltergeist.externalCall(name, args);
    }, name, args);
    return result && result.value;
  };

  return WebPage;

}).call(this);
