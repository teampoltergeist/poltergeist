# Poltergeist - A PhantomJS driver for Capybara #

[![Build Status](https://secure.travis-ci.org/jonleighton/poltergeist.png)](http://travis-ci.org/jonleighton/poltergeist)

Poltergeist is a driver for [Capybara](https://github.com/jnicklas/capybara). It allows you to
run your Capybara tests on a headless [WebKit](http://webkit.org) browser,
provided by [PhantomJS](http://www.phantomjs.org/).

**If you're viewing this at https://github.com/jonleighton/poltergeist,
you're reading the documentation for the master branch.
[View documentation for the latest release
(1.3.0).](https://github.com/jonleighton/poltergeist/tree/v1.3.0)**

## Getting help ##

Questions should be posted [on Stack
Overflow, using the 'poltergeist' tag](http://stackoverflow.com/questions/tagged/poltergeist).

Bug reports should be posted [on
GitHub](https://github.com/jonleighton/poltergeist/issues) (and be sure
to read the bug reporting guidance below).

## Installation ##

Add `poltergeist` to your Gemfile, and in your test setup add:

``` ruby
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
```

If you were previously using the `:rack_test` driver, be aware that
your app will now run in a separate thread and this can have
consequences for transactional tests. [See the Capybara README for more
detail](https://github.com/jnicklas/capybara/blob/master/README.md#transactions-and-database-setup).

## Installing PhantomJS ##

You need at least PhantomJS 1.8.1.  There are *no other external
dependencies* (you don't need Qt, or a running X server, etc.)

### Mac ###

* *Homebrew*: `brew install phantomjs`
* *MacPorts*: `sudo port install phantomjs`
* *Manual install*: [Download this](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.8.1-macosx.zip&can=2&q=)

### Linux ###

* Download the [32
bit](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.8.1-linux-i686.tar.bz2&can=2&q=)
or [64
bit](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.8.1-linux-x86_64.tar.bz2&can=2&q=)
binary.
* Extract the tarball and copy `bin/phantomjs` into your `PATH`

### Windows ###
* Download the [precompiled binary](http://phantomjs.org/download.html) for Windows

### Manual compilation ###

Do this as a last resort if the binaries don't work for you. It will
take quite a long time as it has to build WebKit.

* Download [the source tarball](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.8.1-source.zip&can=2&q=)
* Extract and cd in
* `./build.sh`

(See also the [PhantomJS building
guide](http://phantomjs.org/build.html).)

## Compatibility ##

Poltergeist runs on MRI 1.9, JRuby 1.9 and Rubinius 1.9. Poltergeist
and PhantomJS are currently supported on Mac OS X, Linux, and Windows
platforms.

Ruby 1.8 is no longer supported. The last release to support Ruby 1.8
was 1.0.2, so you should use that if you still need Ruby 1.8 support.

## Running on a CI ##

There are no special steps to take. You don't need Xvfb or any running X
server at all.

[Travis CI](https://travis-ci.org/) has PhantomJS pre-installed, but it
might not be the latest version. If you need to install the latest
version, [check out the .travis.yml that Poltergeist
uses](https://github.com/jonleighton/poltergeist/blob/master/.travis.yml).

Depending on your tests, one thing that you may need is some fonts. If
you're getting errors on a CI that don't occur during development then
try taking some screenshots - it may well be missing fonts throwing
things off kilter. Your distro will have various font packages available
to install.

## What's supported? ##

Poltergeist supports all the mandatory features for a Capybara driver,
and the following optional features:

* `page.evaluate_script` and `page.execute_script`
* `page.within_frame`
* `page.within_window`
* `page.status_code`
* `page.response_headers`
* `page.save_screenshot`
* cookie handling
* drag-and-drop

There are some additional features:

### Taking screenshots with some extensions ###

You can grab screenshots of the page at any point by calling
`save_screenshot('/path/to/file.png')` (this works the same way as the PhantomJS
render feature, so you can specify other extensions like `.pdf`, `.gif`, etc.)

By default, only the viewport will be rendered (the part of the page that is in view). To render
the entire page, use `save_screenshot('/path/to/file.png', :full => true)`.

### Resizing the window ###

Sometimes the window size is important to how things are rendered. Poltergeist sets the window
size to 1024x768 by default, but you can set this yourself with `page.driver.resize(width, height)`.

### Clicking precise coordinates ###

Sometimes its desirable to click a very specific area of the screen. You can accomplish this with
`page.driver.click(x, y)`, where x and y are the screen coordinates.

### Remote debugging (experimental) ###

If you use the `:inspector => true` option (see below), remote debugging
will be enabled.

When this option is enabled, you can insert `page.driver.debug` into
your tests to pause the test and launch a browser which gives you the
WebKit inspector to view your test run with.

You can register this debugger driver with a different name and set it
as the current javascript driver. By example, in your helper file:

```ruby
Capybara.register_driver :poltergeist_debug do |app|
  Capybara::Poltergeist::Driver.new(app, :inspector => true)
end

# Capybara.javascript_driver = :poltergeist
Capybara.javascript_driver = :poltergeist_debug
```

[Read more
here](http://jonathanleighton.com/articles/2012/poltergeist-0-6-0/)

### Manipulating request headers ###

You can manipulate HTTP request headers with these methods:

``` ruby
page.driver.headers # => {}
page.driver.headers = { "User-Agent" => "Poltergeist" }
page.driver.add_headers("Referer" => "https://example.com")
page.driver.headers # => { "User-Agent" => "Poltergeist", "Referer" => "https://example.com" }
```

Notice that `headers=` will overwrite already set headers. You should use
`add_headers` if you want to add a few more. These headers will apply to all
subsequent HTTP requests (including requests for assets, AJAX, etc). They will
be automatically cleared at the end of the test. You have ability to set headers
only for the initial request:

``` ruby
page.driver.headers = { "User-Agent" => "Poltergeist" }
page.driver.add_header("Referer", "http://example.com", permanent: false)
page.driver.headers # => { "User-Agent" => "Poltergeist", "Referer" => "http://example.com" }
visit(login_path)
page.driver.headers # => { "User-Agent" => "Poltergeist" }
```

This way your temporary headers will be sent only for the initial request, all
subsequent request will only contain your permanent headers.

### Inspecting network traffic ###

You can inspect the network traffic (i.e. what resources have been
loaded) on the current page by calling `page.driver.network_traffic`.
This returns an array of request objects. A request object has a
`response_parts` method containing data about the response chunks.

### Manipulating cookies ###

The following methods are used to inspect and manipulate cookies:

* `page.driver.cookies` - a hash of cookies accessible to the current
  page. The keys are cookie names. The values are `Cookie` objects, with
  the following methods: `name`, `value`, `domain`, `path`, `secure?`,
  `httponly?`, `expires`.
* `page.driver.set_cookie(name, value, options = {})` - set a cookie.
  The options hash can take the following keys: `:domain`, `:path`,
  `:secure`, `:httponly`, `:expires`. `:expires` should be a `Time`
  object.
* `page.driver.remove_cookie(name)` - remove a cookie

### Window switching ###

The following methods can be used to execute commands inside different windows:

* `page.driver.window_handles` - an array containing the names of all
  the open windows.

* `page.within_window(name) { # actions }` -  executes
  the passed block in the context of the named window.

Example:

``` ruby
find_link("Login with Facebook").trigger("click")

sleep(0.1)

fb_popup = page.driver.window_handles.last
page.within_window fb_popup do
  fill_in "email", :with => "facebook_email@email.tst"
  fill_in "pass", :with => "my_pass"
  click_button "Log In"
end
```


## Customization ##

You can customize the way that Capybara sets up Poltegeist via the following code in your
test setup:

``` ruby
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, options)
end
```

`options` is a hash of options. The following options are supported:

*   `:phantomjs` (String) - A custom path to the phantomjs executable
*   `:debug` (Boolean) - When true, debug output is logged to `STDERR`.
    Some debug info from the PhantomJS portion of Poltergeist is also
    output, but this goes to `STDOUT` due to technical limitations.
*   `:logger` (Object responding to `puts`) - When present, debug output is written to this object
*   `:phantomjs_logger` (`IO` object) - Where the `STDOUT` from PhantomJS is written to. This is
    where your `console.log` statements will show up. Default: `STDOUT`
*   `:timeout` (Numeric) - The number of seconds we'll wait for a response
    when communicating with PhantomJS. Default is 30.
*   `:inspector` (Boolean, String) - See 'Remote Debugging', above.
*   `:js_errors` (Boolean) - When false, Javascript errors do not get re-raised in Ruby.
*   `:window_size` (Array) - The dimensions of the browser window in which to test, expressed
    as a 2-element array, e.g. [1024, 768]. Default: [1024, 768]
*   `:phantomjs_options` (Array) - Additional [command line options](https://github.com/ariya/phantomjs/wiki/API-Reference)
    to be passed to PhantomJS, e.g. `['--load-images=no', '--ignore-ssl-errors=yes']`
*   `:extensions` (Array) - An array of JS files to be preloaded into
    the phantomjs browser. Useful for faking unsupported APIs.
*   `:port` (Fixnum) - The port which should be used to communicate
    with the PhantomJS process. Default: 44678.

## Troubleshooting ##

Unfortunately, the nature of full-stack testing is that things can and
do go wrong from time to time. This section aims to highlight a number
of common problems and provide ideas about how you can work around them.

### DeadClient errors ###

Sometimes PhantomJS crashes during a test. There are basically two kinds
of crashes: those that can be reproduced every time, and those that
occur sporadically and are not easily reproduced.

If your crash happens every time, you should read the [PhantomJS crash
reporting
guide](https://github.com/ariya/phantomjs/wiki/Crash-Reporting) and file
a bug against PhantomJS. Feel free to also file a bug against
Poltergeist in case there are workarounds that can be implemented within
Poltergeist. Also, if lots of Poltergeist users are experiencing the
same crash then fixing it will move up the priority list.

If your crash is sporadic, there is less that can be done. Often these
issues are very complicated and difficult to track down. It may be that
the crash has already been fixed in a newer version of WebKit that will
eventually find its way into PhantomJS. It's still worth reporting your
bug against PhantomJS, but it's probably not worth filing a bug against
Poltergeist as there's not much we can do.

If you experience sporadic crashes a lot, it may be worth configuring
your CI to automatically re-run failing tests before reporting a failed
build.

### MouseEventFailed errors ###

When Poltergeist clicks on an element, rather than generating a DOM
click event, it actually generates a "proper" click. This is much closer
to what happens when a real user clicks on the page - but it means that
Poltergeist must scroll the page to where the element is, and work out
the correct co-ordinates to click. If the element is covered up by
another element, the click will fail (this is a good thing - because
your user won't be able to click a covered up element either).

Sometimes there can be issues with this behavior. If you have problems,
it's worth taking screenshots of the page and trying to work out what's
going on. If your click is failing, but you're not getting a
`MouseEventFailed` error, then you can turn on the `:debug` option and look
in the output to see what co-ordinates Poltergeist is using for the
click. You can then cross-reference this with a screenshot to see if
something is obviously wrong.

If you can't figure out what's going on and just want to work around the
problem so you can get on with life, consider using a DOM click
event. For example, if this code is failing:

``` ruby
click_button "Save"
```

Then try:

``` ruby
find_button("Save").trigger('click')
```

### Timing problems ###

Sometimes tests pass and fail sporadically. This is often because there
is some problem synchronising events properly. It's often
straightforward to verify this by adding `sleep` statements into your
test to allow sufficient time for the page to settle.

If you have these types of problems, read through the [Capybara
documentation on asynchronous
Javascript](https://github.com/jnicklas/capybara#asynchronous-javascript-ajax-and-friends)
which explains the tools that Capybara provides for dealing with this.

### Memory leak ###

If you run a few capybara sessions manually please make sure you've called
`session.driver.quit` when you don't need session anymore. Forgetting about this
causes memory leakage and your system's resources can be exhausted earlier than
you may expect.

### General troubleshooting hints ###

* Configure Poltergeist with `:debug` turned on so you can see its
  communication with PhantomJS.
* Take screenshots to figure out what the state of your page is when the
  problem occurs.
* Use the remote web inspector in case it provides any useful insight
* Consider downloading the Poltergeist source and using `console.log`
  debugging to figure out what's going on inside PhantomJS. (This will
  require an understanding of the Poltergeist source code and PhantomJS,
  so it's only for the committed!)

### Filing a bug ###

If you can provide specific steps to reproduce your problem, or have
specific information that might help other help you track down the
problem, then please file a bug on Github.

Include as much information as possible. For example:

* Specific steps to reproduce where possible (failing tests are even
  better)
* The output obtained from running Poltergeist with `:debug` turned on
* Screenshots
* Stack traces if there are any Ruby on Javascript exceptions generated
* The Poltergeist and PhantomJS version numbers used
* The operating system name and version used

## Changes ##

### Next release ###

#### Features ####

*   Can set cookies for given domain
*   Can get open window names with window_handles [Issue #178]
*   Added ability to read and append headers (Dmitry Vorotilin) [Issue #187]
*   Added ability to set headers only for the first request (Dmitry Vorotilin) [Issue #337]
*   Depend on Cliver for command-line dependency detection.

#### Bug fixes ####

*   Fix `within_window` finding window after close/open
    (Ryan Schlesinger) [Issue #312]
*   Fix "wrong exec option symbol: pgroup" error on windows (Andrew Meyer)
    [Issue #314]
*   Fixed closing of open pipes after use (driver.quit now performs pipe.close) [Issue #310]
*   Fix NoMethodError when using has_css with a count on svg elements
*   Fix URI::InvalidURIError raised when setting a cookie after loading a
    page with a space in the url [Issue #349]
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

#### Bug fixes #####

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
    `Capybara::Poltergeist::Driver.new( app, :extensions => ['file.js', 'another.js'])`
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

#### Bug fixes ###

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

*   Fix bug where we could end up interacting with an obsolete element. [Issue #30]
*   Raise an suitable error if PhantomJS returns a non-zero exit status.
    Previously a version error would be raised, indicating that the
    PhantomJS version was too old when in fact it did not start at all. [Issue #23]
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

## License ##

Copyright (c) 2011 Jonathan Leighton

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
