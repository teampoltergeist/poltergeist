var __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
Poltergeist.WebPage = (function() {
  var command, delegate, _fn, _fn2, _i, _j, _len, _len2, _ref, _ref2;
  WebPage.CALLBACKS = ['onAlert', 'onConsoleMessage', 'onLoadFinished', 'onInitialized', 'onLoadStarted', 'onResourceRequested', 'onResourceReceived'];
  WebPage.DELEGATES = ['open', 'sendEvent', 'uploadFile', 'release', 'render'];
  WebPage.COMMANDS = ['currentUrl', 'find', 'nodeCall', 'pushFrame', 'popFrame', 'documentSize'];
  function WebPage() {
    var callback, _i, _len, _ref;
    this["native"] = require('webpage').create();
    this.nodes = {};
    this._source = "";
    this._errors = [];
    this.setViewportSize({
      width: 1024,
      height: 768
    });
    _ref = WebPage.CALLBACKS;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      callback = _ref[_i];
      this.bindCallback(callback);
    }
    this.injectAgent();
  }
  _ref = WebPage.COMMANDS;
  _fn = __bind(function(command) {
    return this.prototype[command] = function() {
      var arguments, _ref2;
      _ref2 = arguments, arguments = 1 <= _ref2.length ? __slice.call(_ref2, 0) : [];
      return this.runCommand(command, arguments);
    };
  }, WebPage);
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    command = _ref[_i];
    _fn(command);
  }
  _ref2 = WebPage.DELEGATES;
  _fn2 = __bind(function(delegate) {
    return this.prototype[delegate] = function() {
      return this["native"][delegate].apply(this["native"], arguments);
    };
  }, WebPage);
  for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
    delegate = _ref2[_j];
    _fn2(delegate);
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
    if (this.evaluate(function() {
      return typeof __poltergeist;
    }) === "undefined") {
      return this["native"].injectJs('agent.js');
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
    if (line === 0 && file === "undefined") {
      return this._errors.push(message);
    } else {
      return console.log(message);
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
    if (dimensions.left !== orig_left || dimensions.top !== orig_top) {
      this.setScrollPosition({
        left: dimensions.left,
        top: dimensions.top
      });
    }
    return dimensions;
  };
  WebPage.prototype.get = function(id) {
    var _base;
    return (_base = this.nodes)[id] || (_base[id] = new Poltergeist.Node(this, id));
  };
  WebPage.prototype.evaluate = function() {
    var args, fn;
    fn = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return JSON.parse(this["native"].evaluate("function() { return JSON.stringify(" + (this.stringifyCall(fn, args)) + ") }"));
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
  WebPage.prototype.runCommand = function(name, arguments) {
    var result;
    result = this.evaluate(function(name, arguments) {
      return __poltergeist.externalCall(name, arguments);
    }, name, arguments);
    if (result.error) {
      switch (result.error) {
        case "PoltergeistAgent.ObsoleteNode":
          throw new Poltergeist.ObsoleteNode;
          break;
        default:
          throw result.error;
      }
    } else {
      return result.value;
    }
  };
  return WebPage;
}).call(this);