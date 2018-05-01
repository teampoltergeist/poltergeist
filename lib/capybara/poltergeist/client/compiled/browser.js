var slice = [].slice,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Poltergeist.Browser = (function() {
  function Browser(width, height) {
    this.width = width || 1024;
    this.height = height || 768;
    this.pages = [];
    this.js_errors = true;
    this._debug = false;
    this._counter = 0;
    this._page_settings = null;
    this.processed_modal_messages = [];
    this.confirm_processes = [];
    this.prompt_responses = [];
    this.resetPage();
  }

  Browser.prototype.resetPage = function() {
    var ref;
    ref = [0, []], this._counter = ref[0], this.pages = ref[1];
    if (this.page != null) {
      if (!this.page.closed) {
        if (this.page.frameUrl() !== 'about:blank') {
          this.page.clearLocalStorage();
        }
        this.page.close();
      }
      phantom.clearCookies();
    }
    this.page = this.currentPage = new Poltergeist.WebPage(null, this._page_settings);
    this.page.setViewportSize({
      width: this.width,
      height: this.height
    });
    this.page.handle = "" + (this._counter++);
    this.pages.push(this.page);
    this.processed_modal_messages = [];
    this.confirm_processes = [];
    this.prompt_responses = [];
    this.setupPageHandlers(this.page);
  };

  Browser.prototype.setupPageHandlers = function(page) {
    page["native"]().onAlert = (function(_this) {
      return function(msg) {
        _this.setModalMessage(msg);
      };
    })(this);
    page["native"]().onConfirm = (function(_this) {
      return function(msg) {
        var process;
        process = _this.confirm_processes.pop();
        if (process === void 0) {
          process = true;
        }
        _this.setModalMessage(msg);
        return process;
      };
    })(this);
    page["native"]().onPrompt = (function(_this) {
      return function(msg, defaultVal) {
        var response;
        response = _this.prompt_responses.pop();
        if (response === void 0 || response === false) {
          response = defaultVal;
        }
        _this.setModalMessage(msg);
        return response;
      };
    })(this);
    page.onPageCreated = (function(_this) {
      return function(newPage) {
        var _page;
        _page = new Poltergeist.WebPage(newPage, _this._page_settings);
        _page.handle = "" + (_this._counter++);
        _page.urlBlacklist = page.urlBlacklist;
        _page.urlWhitelist = page.urlWhitelist;
        _page.setViewportSize(page.viewportSize());
        _page.setUserAgent(page.getUserAgent());
        _page.setCustomHeaders(page.getPermanentCustomHeaders());
        _this.setupPageHandlers(_page);
        return _this.pages.push(_page);
      };
    })(this);
  };

  Browser.prototype.getPageByHandle = function(handle) {
    return this.pages.filter(function(p) {
      return !p.closed && p.handle === handle;
    })[0];
  };

  Browser.prototype.runCommand = function(command) {
    this.current_command = command;
    this.currentPage.state = 'default';
    return this[command.name].apply(this, command.args);
  };

  Browser.prototype.debug = function(message) {
    if (this._debug) {
      return console.log("poltergeist [" + (new Date().getTime()) + "] " + message);
    }
  };

  Browser.prototype.setModalMessage = function(msg) {
    this.processed_modal_messages.push(msg);
  };

  Browser.prototype.add_extension = function(extension) {
    if (this.currentPage.injectExtension(extension)) {
      return this.current_command.sendResponse('success');
    } else {
      return this.current_command.sendError(new Poltergeist.BrowserError("Unable to load extension: " + extension));
    }
  };

  Browser.prototype.node = function(page_id, id) {
    if (this.currentPage.id === page_id) {
      return this.currentPage.get(id);
    } else {
      throw new Poltergeist.ObsoleteNode;
    }
  };

  Browser.prototype.visit = function(url, max_wait) {
    var command, loading_page, prevUrl;
    if (max_wait == null) {
      max_wait = 0;
    }
    this.currentPage.state = 'loading';
    this.processed_modal_messages = [];
    this.confirm_processes = [];
    this.prompt_responses = [];
    prevUrl = this.currentPage.source != null ? this.currentPage.currentUrl() : 'about:blank';
    this.currentPage.open(url);
    if (/#/.test(url) && prevUrl.split('#')[0] === url.split('#')[0]) {
      this.currentPage.state = 'default';
      return this.current_command.sendResponse({
        status: 'success'
      });
    } else {
      command = this.current_command;
      loading_page = this.currentPage;
      this.currentPage.waitState('default', function() {
        if (this.statusCode === null && this.status === 'fail') {
          return command.sendError(new Poltergeist.StatusFailError(url));
        } else {
          return command.sendResponse({
            status: this.status
          });
        }
      }, max_wait, function() {
        var msg, resources;
        resources = this.openResourceRequests();
        msg = resources.length ? "Timed out with the following resources still waiting " + (resources.join(',')) : "Timed out with no open resource requests";
        return command.sendError(new Poltergeist.StatusFailError(url, msg));
      });
    }
  };

  Browser.prototype.current_url = function() {
    return this.current_command.sendResponse(this.currentPage.currentUrl());
  };

  Browser.prototype.frame_url = function() {
    return this.current_command.sendResponse(this.currentPage.frameUrl());
  };

  Browser.prototype.status_code = function() {
    return this.current_command.sendResponse(this.currentPage.statusCode);
  };

  Browser.prototype.body = function() {
    return this.current_command.sendResponse(this.currentPage.content());
  };

  Browser.prototype.source = function() {
    return this.current_command.sendResponse(this.currentPage.source);
  };

  Browser.prototype.title = function() {
    return this.current_command.sendResponse(this.currentPage.title());
  };

  Browser.prototype.frame_title = function() {
    return this.current_command.sendResponse(this.currentPage.frameTitle());
  };

  Browser.prototype.find = function(method, selector) {
    return this.current_command.sendResponse({
      page_id: this.currentPage.id,
      ids: this.currentPage.find(method, selector)
    });
  };

  Browser.prototype.find_within = function(page_id, id, method, selector) {
    return this.current_command.sendResponse(this.node(page_id, id).find(method, selector));
  };

  Browser.prototype.all_text = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).allText());
  };

  Browser.prototype.visible_text = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).visibleText());
  };

  Browser.prototype.delete_text = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).deleteText());
  };

  Browser.prototype.property = function(page_id, id, name) {
    return this.current_command.sendResponse(this.node(page_id, id).getProperty(name));
  };

  Browser.prototype.attribute = function(page_id, id, name) {
    return this.current_command.sendResponse(this.node(page_id, id).getAttribute(name));
  };

  Browser.prototype.attributes = function(page_id, id, name) {
    return this.current_command.sendResponse(this.node(page_id, id).getAttributes());
  };

  Browser.prototype.parents = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).parentIds());
  };

  Browser.prototype.value = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).value());
  };

  Browser.prototype.set = function(page_id, id, value) {
    this.node(page_id, id).set(value);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.select_file = function(page_id, id, value) {
    var node;
    node = this.node(page_id, id);
    this.currentPage.beforeUpload(node.id);
    this.currentPage.uploadFile('[_poltergeist_selected]', value);
    this.currentPage.afterUpload(node.id);
    if (phantom.version.major === 2 && phantom.version.minor === 0) {
      return this.click(page_id, id);
    } else {
      return this.current_command.sendResponse(true);
    }
  };

  Browser.prototype.select = function(page_id, id, value) {
    return this.current_command.sendResponse(this.node(page_id, id).select(value));
  };

  Browser.prototype.tag_name = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).tagName());
  };

  Browser.prototype.visible = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).isVisible());
  };

  Browser.prototype.disabled = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).isDisabled());
  };

  Browser.prototype.path = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).path());
  };

  Browser.prototype.evaluate = function() {
    var arg, args, i, len, ref, script;
    script = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    for (i = 0, len = args.length; i < len; i++) {
      arg = args[i];
      if (this._isElementArgument(arg)) {
        if (arg["ELEMENT"]["page_id"] !== this.currentPage.id) {
          throw new Poltergeist.ObsoleteNode;
        }
      }
    }
    return this.current_command.sendResponse((ref = this.currentPage).evaluate.apply(ref, ["function() { return " + script + " }"].concat(slice.call(args))));
  };

  Browser.prototype.evaluate_async = function() {
    var arg, args, cb, command, i, len, max_wait, ref, script;
    script = arguments[0], max_wait = arguments[1], args = 3 <= arguments.length ? slice.call(arguments, 2) : [];
    for (i = 0, len = args.length; i < len; i++) {
      arg = args[i];
      if (this._isElementArgument(arg)) {
        if (arg["ELEMENT"]["page_id"] !== this.currentPage.id) {
          throw new Poltergeist.ObsoleteNode;
        }
      }
    }
    command = this.current_command;
    cb = (function(_this) {
      return function(result) {
        return command.sendResponse(result);
      };
    })(this);
    (ref = this.currentPage).evaluate_async.apply(ref, ["function() { " + script + " }", cb].concat(slice.call(args)));
    return setTimeout((function(_this) {
      return function() {
        return command.sendError(new Poltergeist.ScriptTimeoutError);
      };
    })(this), max_wait * 1000);
  };

  Browser.prototype.execute = function() {
    var arg, args, i, len, ref, script;
    script = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    for (i = 0, len = args.length; i < len; i++) {
      arg = args[i];
      if (this._isElementArgument(arg)) {
        if (arg["ELEMENT"]["page_id"] !== this.currentPage.id) {
          throw new Poltergeist.ObsoleteNode;
        }
      }
    }
    (ref = this.currentPage).execute.apply(ref, ["function() { " + script + " }"].concat(slice.call(args)));
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.frameUrlFor = function(frame_name) {
    return this.currentPage.frameUrlFor(frame_name);
  };

  Browser.prototype.pushFrame = function(command, name, timeout) {
    var frame, frame_url;
    if (Array.isArray(name)) {
      frame = this.node.apply(this, name);
      name = frame.getAttribute('name') || frame.getAttribute('id');
      if (!name) {
        frame.setAttribute('name', "_random_name_" + (new Date().getTime()));
        name = frame.getAttribute('name');
      }
    }
    frame_url = this.frameUrlFor(name);
    if (indexOf.call(this.currentPage.blockedUrls(), frame_url) >= 0) {
      return command.sendResponse(true);
    } else if (this.currentPage.pushFrame(name)) {
      if (frame_url && (frame_url !== 'about:blank') && (this.currentPage.frameUrl() === 'about:blank')) {
        this.currentPage.state = 'awaiting_frame_load';
        return this.currentPage.waitState('default', function() {
          return command.sendResponse(true);
        });
      } else {
        return command.sendResponse(true);
      }
    } else {
      if (new Date().getTime() < timeout) {
        return setTimeout(((function(_this) {
          return function() {
            return _this.pushFrame(command, name, timeout);
          };
        })(this)), 50);
      } else {
        return command.sendError(new Poltergeist.FrameNotFound(name));
      }
    }
  };

  Browser.prototype.push_frame = function(name, timeout) {
    if (timeout == null) {
      timeout = (new Date().getTime()) + 2000;
    }
    return this.pushFrame(this.current_command, name, timeout);
  };

  Browser.prototype.pop_frame = function(pop_all) {
    if (pop_all == null) {
      pop_all = false;
    }
    return this.current_command.sendResponse(this.currentPage.popFrame(pop_all));
  };

  Browser.prototype.window_handles = function() {
    var handles;
    handles = this.pages.filter(function(p) {
      return !p.closed;
    }).map(function(p) {
      return p.handle;
    });
    return this.current_command.sendResponse(handles);
  };

  Browser.prototype.window_handle = function(name) {
    var handle, page;
    if (name == null) {
      name = null;
    }
    handle = name ? (page = this.pages.filter(function(p) {
      return !p.closed && p.windowName() === name;
    })[0], page ? page.handle : null) : this.currentPage.handle;
    return this.current_command.sendResponse(handle);
  };

  Browser.prototype.switch_to_window = function(handle) {
    var command, new_page;
    command = this.current_command;
    new_page = this.getPageByHandle(handle);
    if (new_page) {
      if (new_page !== this.currentPage) {
        return new_page.waitState('default', (function(_this) {
          return function() {
            _this.currentPage = new_page;
            return command.sendResponse(true);
          };
        })(this));
      } else {
        return command.sendResponse(true);
      }
    } else {
      throw new Poltergeist.NoSuchWindowError;
    }
  };

  Browser.prototype.open_new_window = function() {
    this.execute('window.open()');
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.close_window = function(handle) {
    var page;
    page = this.getPageByHandle(handle);
    if (page) {
      page.close();
      return this.current_command.sendResponse(true);
    } else {
      return this.current_command.sendResponse(false);
    }
  };

  Browser.prototype.mouse_event = function(page_id, id, name, keys, offset) {
    var command, event_page, last_mouse_event, node;
    if (keys == null) {
      keys = [];
    }
    if (offset == null) {
      offset = {};
    }
    node = this.node(page_id, id);
    this.currentPage.state = 'mouse_event';
    last_mouse_event = node.mouseEvent(name, keys, offset);
    event_page = this.currentPage;
    command = this.current_command;
    return setTimeout(function() {
      if (event_page.state === 'mouse_event') {
        event_page.state = 'default';
        return command.sendResponse({
          position: last_mouse_event
        });
      } else {
        return event_page.waitState('default', function() {
          return command.sendResponse({
            position: last_mouse_event
          });
        });
      }
    }, 5);
  };

  Browser.prototype.click = function(page_id, id, keys, offset) {
    return this.mouse_event(page_id, id, 'click', keys, offset);
  };

  Browser.prototype.right_click = function(page_id, id, keys, offset) {
    return this.mouse_event(page_id, id, 'rightclick', keys, offset);
  };

  Browser.prototype.double_click = function(page_id, id, keys, offset) {
    return this.mouse_event(page_id, id, 'doubleclick', keys, offset);
  };

  Browser.prototype.hover = function(page_id, id) {
    return this.mouse_event(page_id, id, 'mousemove');
  };

  Browser.prototype.click_coordinates = function(x, y) {
    this.currentPage.sendEvent('click', x, y);
    return this.current_command.sendResponse({
      click: {
        x: x,
        y: y
      }
    });
  };

  Browser.prototype.drag = function(page_id, id, other_id) {
    this.node(page_id, id).dragTo(this.node(page_id, other_id));
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.drag_by = function(page_id, id, x, y) {
    this.node(page_id, id).dragBy(x, y);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.trigger = function(page_id, id, event) {
    this.node(page_id, id).trigger(event);
    return this.current_command.sendResponse(event);
  };

  Browser.prototype.equals = function(page_id, id, other_id) {
    return this.current_command.sendResponse(this.node(page_id, id).isEqual(this.node(page_id, other_id)));
  };

  Browser.prototype.reset = function() {
    this.resetPage();
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.scroll_to = function(left, top) {
    this.currentPage.setScrollPosition({
      left: left,
      top: top
    });
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.send_keys = function(page_id, id, keys) {
    var target;
    target = this.node(page_id, id);
    if (!target.containsSelection()) {
      target.mouseEvent('click');
    }
    this._send_keys_with_modifiers(keys);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype._send_keys_with_modifiers = function(keys, current_modifier_code) {
    var i, j, k, key, len, len1, len2, modifier_code, modifier_key, modifier_keys, sequence;
    if (current_modifier_code == null) {
      current_modifier_code = 0;
    }
    for (i = 0, len = keys.length; i < len; i++) {
      sequence = keys[i];
      if (sequence.key != null) {
        if (!(key = this.currentPage.keyCode(sequence.key))) {
          this.current_command.sendError(new Poltergeist.KeyError("Unknown key: " + sequence.key));
          return;
        }
      } else if (sequence.keys != null) {
        key = sequence.keys;
      } else {
        key = sequence;
      }
      if (sequence.modifier != null) {
        modifier_keys = this.currentPage.keyModifierKeys(sequence.modifier);
        modifier_code = this.currentPage.keyModifierCode(sequence.modifier) | current_modifier_code;
        for (j = 0, len1 = modifier_keys.length; j < len1; j++) {
          modifier_key = modifier_keys[j];
          this.currentPage.sendEvent('keydown', modifier_key);
        }
        this._send_keys_with_modifiers([].concat(key), modifier_code);
        for (k = 0, len2 = modifier_keys.length; k < len2; k++) {
          modifier_key = modifier_keys[k];
          this.currentPage.sendEvent('keyup', modifier_key);
        }
      } else {
        this.currentPage.sendEvent('keypress', key, null, null, current_modifier_code);
      }
    }
    return true;
  };

  Browser.prototype.render_base64 = function(format, arg1) {
    var dimensions, encoded_image, full, ref, ref1, ref2, ref3, selector, window_scroll_position;
    ref = arg1 != null ? arg1 : {}, full = (ref1 = ref.full) != null ? ref1 : false, selector = (ref2 = ref.selector) != null ? ref2 : null;
    window_scroll_position = this.currentPage["native"]().evaluate("function(){ return [window.pageXOffset, window.pageYOffset] }");
    dimensions = this.set_clip_rect(full, selector);
    encoded_image = this.currentPage.renderBase64(format);
    this.currentPage.setScrollPosition({
      left: dimensions.left,
      top: dimensions.top
    });
    (ref3 = this.currentPage["native"]()).evaluate.apply(ref3, ["window.scrollTo"].concat(slice.call(window_scroll_position)));
    return this.current_command.sendResponse(encoded_image);
  };

  Browser.prototype.render = function(path, arg1) {
    var dimensions, format, full, options, quality, ref, ref1, ref2, ref3, ref4, ref5, selector, window_scroll_position;
    ref = arg1 != null ? arg1 : {}, full = (ref1 = ref.full) != null ? ref1 : false, selector = (ref2 = ref.selector) != null ? ref2 : null, format = (ref3 = ref.format) != null ? ref3 : null, quality = (ref4 = ref.quality) != null ? ref4 : null;
    window_scroll_position = this.currentPage["native"]().evaluate("function(){ return [window.pageXOffset, window.pageYOffset] }");
    dimensions = this.set_clip_rect(full, selector);
    options = {};
    if (format != null) {
      options["format"] = format;
    }
    if (quality != null) {
      options["quality"] = quality;
    }
    this.currentPage.setScrollPosition({
      left: 0,
      top: 0
    });
    this.currentPage.render(path, options);
    this.currentPage.setScrollPosition({
      left: dimensions.left,
      top: dimensions.top
    });
    (ref5 = this.currentPage["native"]()).evaluate.apply(ref5, ["window.scrollTo"].concat(slice.call(window_scroll_position)));
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_clip_rect = function(full, selector) {
    var dimensions, document, rect, ref, viewport;
    dimensions = this.currentPage.validatedDimensions();
    ref = [dimensions.document, dimensions.viewport], document = ref[0], viewport = ref[1];
    rect = full ? {
      left: 0,
      top: 0,
      width: document.width,
      height: document.height
    } : selector != null ? this.currentPage.elementBounds(selector) : {
      left: 0,
      top: 0,
      width: viewport.width,
      height: viewport.height
    };
    this.currentPage.setClipRect(rect);
    return dimensions;
  };

  Browser.prototype.set_paper_size = function(size) {
    this.currentPage.setPaperSize(size);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_zoom_factor = function(zoom_factor) {
    this.currentPage.setZoomFactor(zoom_factor);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.resize = function(width, height) {
    this.currentPage.setViewportSize({
      width: width,
      height: height
    });
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.network_traffic = function(type) {
    return this.current_command.sendResponse(this.currentPage.networkTraffic(type));
  };

  Browser.prototype.clear_network_traffic = function() {
    this.currentPage.clearNetworkTraffic();
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_proxy = function(ip, port, type, user, password) {
    phantom.setProxy(ip, port, type, user, password);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.get_headers = function() {
    return this.current_command.sendResponse(this.currentPage.getCustomHeaders());
  };

  Browser.prototype.set_headers = function(headers) {
    return this.add_headers(headers, false, false);
  };

  Browser.prototype.add_headers = function(headers, local, keepExisting) {
    var pages;
    if (local == null) {
      local = false;
    }
    if (keepExisting == null) {
      keepExisting = true;
    }
    pages = local ? [this.currentPage] : this.pages;
    pages.forEach((function(_this) {
      return function(page) {
        var allHeaders, name, value;
        allHeaders = keepExisting ? page.getCustomHeaders() : {};
        for (name in headers) {
          value = headers[name];
          allHeaders[name] = value;
        }
        if (allHeaders['User-Agent']) {
          page.setUserAgent(allHeaders['User-Agent']);
        }
        return page.setCustomHeaders(allHeaders);
      };
    })(this));
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.add_header = function(header, arg1) {
    var permanent, ref;
    permanent = (ref = arg1.permanent) != null ? ref : true;
    if (permanent !== true) {
      this.currentPage.addTempHeader(header);
      if (permanent === "no_redirect") {
        this.currentPage.addTempHeaderToRemoveOnRedirect(header);
      }
    }
    return this.add_headers(header, permanent !== true);
  };

  Browser.prototype.response_headers = function() {
    return this.current_command.sendResponse(this.currentPage.responseHeaders());
  };

  Browser.prototype.cookies = function() {
    return this.current_command.sendResponse(this.currentPage.cookies());
  };

  Browser.prototype.set_cookie = function(cookie) {
    phantom.addCookie(cookie);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.remove_cookie = function(name) {
    this.currentPage.deleteCookie(name);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.clear_cookies = function() {
    phantom.clearCookies();
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.cookies_enabled = function(flag) {
    phantom.cookiesEnabled = flag;
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_http_auth = function(user, password) {
    this.currentPage.setHttpAuth(user, password);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_js_errors = function(value) {
    this.js_errors = value;
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_debug = function(value) {
    this._debug = value;
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_page_settings = function(settings) {
    this._page_settings = settings;
    this.page.setSettings(this._page_settings);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.exit = function() {
    return phantom.exit();
  };

  Browser.prototype.noop = function() {};

  Browser.prototype.browser_error = function() {
    throw new Error('zomg');
  };

  Browser.prototype.go_back = function() {
    if (this.currentPage.canGoBack) {
      this.currentPage.state = 'wait_for_loading';
      this.currentPage.goBack();
      return this._waitForHistoryChange();
    } else {
      return this.current_command.sendResponse(false);
    }
  };

  Browser.prototype.go_forward = function() {
    if (this.currentPage.canGoForward) {
      this.currentPage.state = 'wait_for_loading';
      this.currentPage.goForward();
      return this._waitForHistoryChange();
    } else {
      return this.current_command.sendResponse(false);
    }
  };

  Browser.prototype.refresh = function() {
    this.currentPage.state = 'wait_for_loading';
    this.currentPage.reload();
    return this._waitForHistoryChange();
  };

  Browser.prototype.set_url_whitelist = function() {
    var wc, wildcards;
    wildcards = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    this.currentPage.urlWhitelist = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = wildcards.length; i < len; i++) {
        wc = wildcards[i];
        results.push(this._wildcardToRegexp(wc));
      }
      return results;
    }).call(this);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_url_blacklist = function() {
    var wc, wildcards;
    wildcards = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    this.currentPage.urlBlacklist = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = wildcards.length; i < len; i++) {
        wc = wildcards[i];
        results.push(this._wildcardToRegexp(wc));
      }
      return results;
    }).call(this);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_confirm_process = function(process) {
    this.confirm_processes.push(process);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_prompt_response = function(response) {
    this.prompt_responses.push(response);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.modal_message = function() {
    return this.current_command.sendResponse(this.processed_modal_messages.shift());
  };

  Browser.prototype.clear_memory_cache = function() {
    this.currentPage.clearMemoryCache();
    return this.current_command.sendResponse(true);
  };

  Browser.prototype._waitForHistoryChange = function() {
    var command;
    command = this.current_command;
    return this.currentPage.waitState(['loading', 'default'], function(cur_state) {
      if (cur_state === 'loading') {
        return this.waitState('default', function() {
          return command.sendResponse(true);
        });
      } else {
        return command.sendResponse(true);
      }
    }, 0.5, function() {
      this.state = 'default';
      return command.sendResponse(true);
    });
  };

  Browser.prototype._wildcardToRegexp = function(wildcard) {
    wildcard = wildcard.replace(/[\-\[\]\/\{\}\(\)\+\.\\\^\$\|]/g, "\\$&");
    wildcard = wildcard.replace(/\*/g, ".*");
    wildcard = wildcard.replace(/\?/g, ".");
    return new RegExp(wildcard, "i");
  };

  Browser.prototype._isElementArgument = function(arg) {
    return typeof arg === "object" && typeof arg['ELEMENT'] === "object";
  };

  return Browser;

})();
