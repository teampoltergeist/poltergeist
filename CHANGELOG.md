### Next release ###

#### Features ####

*   Added ability to set zoom_factor (Dmytro Budnyk)
*   Write JSON to the logger, rather than Ruby [Issue #430]
*   Added ability to access all of a nodes attributes (Jon Rowe)

#### Bug fixes ####

*   Fix `set` appending to `contenteditable` instead of replacing its text
    (Pedro Carriço and Erik Ostrom) [Issue #432]
*   Raise exception on PhantomJS "status: fail" result (i.e DNS issue) instead
    of returning minimal HTML body (Dean Holdren) [Issue #473]

### 1.5.0 ###

#### Features ####

*   Added ability to clear network traffic (Vick Vu)
*   Added ability to set paper_size via a driver setter (Philippe Lehoux)
*   Can support Basic HTTP authentication
*   Added basic implementation of `send_keys`
*   Added ability to go_back, go_forward, set the contents of a contenteditable
    element and Capybara 2.2 support (Pedro Carriço)

#### Bug fixes ####

*   Use `Capybara::Helpers.normalize_whitespace` in filter_text to strip unicode
    whitespace (Wataru Miyaguni)
*   Fix missed interpolation on deprecated error classes
*   Raise InvalidSelector when wrong xpath selector was used [Issue #395]
*   Fix `driver.quit` before visiting any url with `IOError` error [Issue #398]
*   Fix JRuby support when PhantomJS quits first  [Issue #382, #404]
*   Fix ability to pass element to `within_frame`  [Issue #414]
*   Fix setting negatives in number inputs (John Hawthorn)

### 1.4.1 ###

#### Bug fixes ####

*   Kill thread first off and then close IO [Issue #385]

### 1.4.0 ###

#### Features ####

*   Can set cookies for given domain
*   Can get open window names with window_handles [Issue #178]
*   Added ability to read and append headers (Dmitry Vorotilin) [Issue #187]
*   Added ability to set headers only for the first request
    (Dmitry Vorotilin) [Issue #337]
*   Depend on Cliver for command-line dependency detection.
*   Added ability to scroll with `driver.scroll_to left, top` (Jim Lim)
*   Added ability to capture an element  with `driver.render selector: '#id'`
    (Jim Lim)
*   Added ability to render base64-encoded image with `driver.render_base64`
    (Jim Lim) [Issue #189]

#### Bug fixes ####

*   Fix clicks inside `within_frame` not taking into account padding on the
    frame [Issue #377]
*   Fix `within_window` finding window after close/open
    (Ryan Schlesinger) [Issue #312]
*   Fix "wrong exec option symbol: pgroup" error on windows (Andrew Meyer)
    [Issue #314]
*   Fixed closing of open pipes after use (driver.quit now performs pipe.close)
    [Issue #310]
*   Fix NoMethodError when using has_css with a count on svg elements
*   Fix URI::InvalidURIError raised when setting a cookie after loading a
    page with a space in the url or when using Capybara::Session#current_path
    [Issue #349]
*   Fix leak of phantomjs processes by adding a GC finalizer to the
    Capybara::Poltergeist::Client object that creates them [Issue #348]

### 1.3.0 ###

#### Features ####

*   Add support for PhantomJS 1.7's `cookiesEnabled` API
    (Micah Frost)

#### Bug fixes ####

*   Fix logging of mouse event co-ordinates
*   Invalid selectors throw a useful error message
*   Tie us to the 0.4 version of faye-websocket since the 0.5 version
    contains breaking changes.

### 1.2.0 ###

#### Features ####

*   Support for Windows hosted Poltergeist (Aaron Tull).
*   Capybara 2.1 support

#### Bug fixes ####

*   Reverted the "native" implementation for filling in form fields,
    which was introduced in 1.0. This implementation caused various bugs
    and in general doesn't seem to be worth the trouble at the moment.
    It can be reconsidered in the future when PhantomJS has upgraded its
    WebKit version. [Issue #176, #223]
*   Run phantomjs in a new process group so ^C doesn't trigger a
    DeadClient error [Issue #252]

### 1.1.2 ###

#### Bug fixes ####

*   Tie to faye-websocket 0.4 as 0.5 introduces incompatibilities.

### 1.1.1 ###

#### Features ####

*   Changed Capybara dependency to `~> 2.0.1` because Poltergeist 1.1 is
    not compatible with Capybara 2.1.

### 1.1.0 ###

#### Features ####

*   Add support for custom phantomjs loggers via `:phantomjs_logger` option.
    (Gabe Bell)
*   Add `page.driver.click(x, y)` to click precise coordinates.
    (Micah Geisel)
*   Add Capybara 2.0 support. Capybara 1.1 and Ruby 1.8 are *no
    longer supported*. (Mauro Asprea) [Issue #163]
*   Add `node.base.double_click` to double click the node.
    (Andy Shen)
*   The `:debug` option now causes the PhantomJS portion of Poltergeist
    to output some additional debug info, which may be useful in
    figuring out timeout errors.
*   Add the ability to extend the phantomjs environment via browser
    options. e.g.
    `Capybara::Poltergeist::Driver.new(app, :extensions => ['file.js', 'another.js'])`
    (Jon Rowe)

#### Bug fixes ####

*   Fix timing issue when using `within_frame` that could cause errors.
    [Issue #183, #211] (@errm, @motemen)
*   Fix bug with `within_frame` not properly switching the context back
    after the block has executed. [Issue #242]
*   Fix calculation of click position when clicking within a frame.
    [Issue #222, #225]
*   Fix error raising when calling `expires` if not set on cookie.
    [Issue #203] (@arnvald)
*   Fix the `:js_errors` option. Previously errors were not being
    reported, but would still cause commands to fail. [Issue #229]
*   Fix incorrect time zone handling when setting cookie expiry time
    [Issue #228]
*   Send SIGKILL to PhantomJS if it doesn't exit within 2 seconds
    [Issue #196]
*   Provide a more informative message for the `ObsoleteNode` error.
    [Issue #192]
*   Fix `ObsoleteNode` error when using `attach_file` with the `jQuery
    File Upload` plugin. [Issue #115]
*   Ensure that a `String` is passed over-the-wire to PhantomJS for
    file input paths, allowing `attach_file` to be called with arbitry
    objects such as a Pathname. (@mjtko) [Issue #215]
*   Cookies can now be set before the first request. [Issue #193]

### 1.0.3 ###

#### Bug fixes ####

*   Tied to faye-websocket 0.4, as 0.5 introduces incompatibilities.

### 1.0.2 ###

#### Bug fixes ####

*   Clearing the value before setting a new value by sending a backspace.
    This fixes the issue that you can't set an empty value. [Issue #184]

### 1.0.1 ###

#### Bug fixes ####

*   Don't use a fixed port number by default; find an available port.
    The port can still be configured to a fixed value using the `:port`
    option. The reverts the default behaviour to how it was before the
    1.0 release. [Issue #174]

### 1.0 ###

#### Features ####

*   Click co-ordinates are shown in the debug log. You can use this in
    combination with `page.driver.render` to work out where clicks are
    actually happening if you are having trouble.
*   Added `:port` configuration option and made the default port 44678
    rather than a random available port.
*   Support for Capybara's `page.response_headers` API to retrieve the
    headers of the last page load.
*   Support for cookie manipulation. [Issue #12]
*   Frame switching support now uses native PhantomJS APIs. (This might
    make it work better, but in general it's a badly tested area both in
    Capybara and Poltergeist.)
*   Support for the Capybara window switching API (`page.within_window`).

#### Bug fixes ####

*   Prevent `TypeError: 'undefined' is not an object (evaluating
    'rect.top')` error when clicking an element with `display: none`.
    The click will fail, but an obsolete node error will be raised, meaning
    that Capybara's retry mechanisms will kick in. [Issue #130]
*   Mouse over the element we will click, before clicking it. This
    enables `:hover` effects etc to trigger before the click happens,
    which can affect the click in some cases. [Issue #120]
*   Don't blow up when `evaluate_script` is called with a cyclic
    structure.
*   Fix the text method for title elements, so it doesn't return an
    empty string.
*   Fixed problem with cookies not being clearer between tests on
    PhantomJS 1.7
*   Fixed Javascript errors during page load causes TimeoutErrors.
    [Issue #124]
*   Ensure the User-Agent header can be set successfully. (Klaus Hartl)
    [Issue #127]
*   Use `el.innerText` for `Node#text`. This ensures that e.g. `<br>` is
    returned as a space. It also simplifies the method. [Issue #139]
*   Fix status code support when a response redirects to another URL.
    This was previously tested to ensure it would return the status code
    of the redirected URL, but the test was falsely broken and the
    implementation was also broken.
*   Fixed visiting URLs where only a hash change occurs (no HTTP
    request). [Issue #79]
*   Setting `page.driver.headers` now applies the headers to all
    requests, not just calls to `visit`. (So XHR, asset requests, etc
    will all receive the headers.) [Issue #149]

### 0.7 ###

#### Features ####

*   Added an option `:js_errors`, allowing poltergeist to continue
    running after JS errors. (John Griffin & Tom Stuart) [Issue #62] [Issue #69]
*   Added an option `:window_size`, allowing users to specify
    dimensions to which the browser window will be resized.
    (Tom Stuart) [Issue #53]
*   Capybara 1.0 is no longer supported. Capybara ~> 1.1 is required.
*   Added ability to set arbitrary http request headers
*   Inspect network traffic on the page via
    `page.driver.network_traffic` (Doug McInnes) [Issue #77]
*   Added an option `:phantomjs_options`, allowing users to specify
    additional command-line options passed to phantomjs executable.
    (wynst) [Issue #97]
*   Scroll element into viewport if needed on click (Gabriel Sobrinho)
    [Issue #83]
*   Added status code support. (Dmitriy Nesteryuk and Jon Leighton) [Issue #37]

#### Bug fixes ####

*   Fix issue with `ClickFailed` exception happening with a negative
    co-ordinate (which should be impossible). (Jon Leighton, Gabriel
    Sobrinho, Tom Stuart) [Issue #60]
*   Fix issue with `undefined method map for "[]":String`, which
    happened when dealing with pages that include JS rewriting
    Array.prototype.toJSON. (Tom Stuart) [Issue #63]

### 0.6 ###

#### Features ####

*   Updated to PhantomJS 1.5.0, giving us proper support for reporting
    Javascript exception backtraces.

### 0.5 ###

#### Features ####

*   Detect if clicking an element will fail. If the click will actually
    hit another element (because that element is in front of the one we
    want to click), the user will now see an exception explaining what
    happened and which element would actually be targeted by the click. This
    should aid debugging. [Issue #25]
*   Click elements at their middle position rather than the top-left.
    This is presumed to be more likely to succeed because the top-left
    may be obscured by overlapping elements, negative margins, etc. [Issue #26]
*   Add experimental support for using the remote WebKit web inspector.
    This will only work with PhantomJS 1.5, which is not yet released,
    so it won't be officially supported by Poltergeist until 1.5 is
    released. [Issue #31]
*   Add `page.driver.quit` method. If you spawn additional Capybara
    sessions, you might want to use this to reap the child phantomjs
    process. [Issue #24]
*   Errors produced by Javascript on the page will now generate an
    exception within Ruby. [Issue #27]
*   JRuby support. [Issue #20]

#### Bug fixes ####

*   Fix bug where we could end up interacting with an obsolete element.
    [Issue #30]
*   Raise an suitable error if PhantomJS returns a non-zero exit status.
    Previously a version error would be raised, indicating that the
    PhantomJS version was too old when in fact it did not start at all.
    [Issue #23]
*   Ensure the `:timeout` option is actually used. [Issue #36]
*   Nodes need to know which page they are associated with. Before this,
    if Javascript caused a new page to load, existing node references
    would be wrong, but wouldn't raise an ObsoleteNode error. [Issue #39]
*   In some circumstances, we could end up missing an inline element
    when attempting to click it. This is due to the use of
    `getBoundingClientRect()`. We're now using `getClientRects()` to
    address this.

### 0.4 ###

*   Element click position is now calculated using the native
    `getBoundingClientRect()` method, which will be faster and less
    buggy.
*   Handle `window.confirm()`. Always returns true, which is the same
    as capybara-webkit. [Issue #10]
*   Handle `window.prompt()`. Returns the default value, if present, or
    null.
*   Fix bug with page Javascript page loading causing problems. [Issue #19]

### 0.3 ###

*   There was a bad bug to do with clicking elements in a page where the
    page is smaller than the window. The incorrect position would be
    calculated, and so the click would happen in the wrong place. This is
    fixed. [Issue #8]
*   Poltergeist didn't work in conjunction with the Thin web server,
    because that server uses Event Machine, and Poltergeist was assuming
    that it was the only thing in the process using EventMachine.

    To solve this, EventMachine usage has been completely removed, which
    has the welcome side-effect of being more efficient because we
    no longer have the overhead of running a mostly-idle event loop.

    [Issue #6]
*   Added the `:timeout` option to configure the timeout when talking to
    PhantomJS.

### 0.2 ###

*   First version considered 'ready', hopefully fewer problems.

### 0.1 ###

*   First version, various problems.
