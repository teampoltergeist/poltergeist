var __slice = [].slice;

Poltergeist.Browser = (function() {

  function Browser(owner, width, height) {
    this.owner = owner;
    this.width = width || 1024;
    this.height = height || 768;
    this.state = 'default';
    this.page_id = 0;
    this.resetPage();
  }

  Browser.prototype.resetPage = function() {
    var _this = this;
    if (this.page != null) {
      this.page.release();
    }
    this.page = new Poltergeist.WebPage(this.width, this.height);
    this.page.onLoadStarted = function() {
      if (_this.state === 'clicked') {
        return _this.state = 'loading';
      }
    };
    this.page.onLoadFinished = function(status) {
      if (_this.state === 'loading') {
        _this.sendResponse(status);
        return _this.state = 'default';
      }
    };
    return this.page.onInitialized = function() {
      return _this.page_id += 1;
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

  Browser.prototype.getNode = function(page_id, id, callback) {
    if (page_id === this.page_id) {
      return callback.call(this, this.page.get(id));
    } else {
      return this.owner.sendError(new Poltergeist.ObsoleteNode);
    }
  };

  Browser.prototype.nodeCall = function() {
    var args, callback, fn, id, page_id;
    page_id = arguments[0], id = arguments[1], fn = arguments[2], args = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
    callback = args.pop();
    return this.getNode(page_id, id, function(node) {
      var result;
      result = node[fn].apply(node, args);
      if (result instanceof Poltergeist.ObsoleteNode) {
        return this.owner.sendError(result);
      } else {
        return callback.call(this, result, node);
      }
    });
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
    return this.nodeCall(page_id, id, 'find', selector, this.sendResponse);
  };

  Browser.prototype.text = function(page_id, id) {
    return this.nodeCall(page_id, id, 'text', this.sendResponse);
  };

  Browser.prototype.attribute = function(page_id, id, name) {
    return this.nodeCall(page_id, id, 'getAttribute', name, this.sendResponse);
  };

  Browser.prototype.value = function(page_id, id) {
    return this.nodeCall(page_id, id, 'value', this.sendResponse);
  };

  Browser.prototype.set = function(page_id, id, value) {
    return this.nodeCall(page_id, id, 'set', value, function() {
      return this.sendResponse(true);
    });
  };

  Browser.prototype.select_file = function(page_id, id, value) {
    return this.nodeCall(page_id, id, 'isMultiple', function(multiple, node) {
      if (multiple) {
        node.removeAttribute('multiple');
      }
      node.setAttribute('_poltergeist_selected', '');
      this.page.uploadFile('[_poltergeist_selected]', value);
      node.removeAttribute('_poltergeist_selected');
      if (multiple) {
        node.setAttribute('multiple', 'multiple');
      }
      return this.sendResponse(true);
    });
  };

  Browser.prototype.select = function(page_id, id, value) {
    return this.nodeCall(page_id, id, 'select', value, this.sendResponse);
  };

  Browser.prototype.tag_name = function(page_id, id) {
    return this.nodeCall(page_id, id, 'tagName', this.sendResponse);
  };

  Browser.prototype.visible = function(page_id, id) {
    return this.nodeCall(page_id, id, 'isVisible', this.sendResponse);
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
    return this.nodeCall(page_id, id, 'isObsolete', function(obsolete, node) {
      var click,
        _this = this;
      this.state = 'clicked';
      click = node.click();
      return setTimeout(function() {
        if (_this.state === 'clicked') {
          _this.state = 'default';
          if (click instanceof Poltergeist.ClickFailed) {
            return _this.owner.sendError(click);
          } else {
            return _this.sendResponse(true);
          }
        }
      }, 10);
    });
  };

  Browser.prototype.drag = function(page_id, id, other_id) {
    return this.nodeCall(page_id, id, 'isObsolete', function(obsolete, node) {
      node.dragTo(this.page.get(other_id));
      return this.sendResponse(true);
    });
  };

  Browser.prototype.trigger = function(page_id, id, event) {
    return this.nodeCall(page_id, id, 'trigger', event, function() {
      return this.sendResponse(event);
    });
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

  Browser.prototype.networkTraffic = function(filter) {
    var id, matches, traffic, _ref;
    matches = [];
    _ref = this.page.networkTraffic();
    for (id in _ref) {
      traffic = _ref[id];
      if (!filter || traffic.request.url.match(filter)) {
        matches.push(traffic);
      }
    }
    return this.sendResponse(matches);
  };

  Browser.prototype.exit = function() {
    return phantom.exit();
  };

  Browser.prototype.noop = function() {};

  return Browser;

})();
