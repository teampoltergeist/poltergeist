# Poltergeist - A PhantomJS driver for Capybara #

Version: 0.6.0

[![Build Status](https://secure.travis-ci.org/jonleighton/poltergeist.png)](http://travis-ci.org/jonleighton/poltergeist)
[![Dependency Status](https://gemnasium.com/jonleighton/poltergeist.png)](https://gemnasium.com/jonleighton/poltergeist)

Poltergeist is a driver for [Capybara](https://github.com/jnicklas/capybara). It allows you to
run your Capybara tests on a headless [WebKit](http://webkit.org) browser,
provided by [PhantomJS](http://www.phantomjs.org/).

## Installation ##

Add `poltergeist` to your Gemfile, and in your test setup add:

``` ruby
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
```

## Installing PhantomJS ##

You need PhantomJS 1.6.0. There are no other dependencies (you don't
need Qt, or Xvfb, etc.)

**Note**: Poltergeist 0.6 (the latest release) has a compatibility
issue with PhantomJS 1.6 (the latest version, released 20th June). So use
PhantomJS 1.5 for now. Poltergeist 0.7 will be release soon, with an
update to support PhantomJS 1.6.

### Mac ###

* *With homebrew*: `brew install phantomjs`
* *Without homebrew*: [Download this](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.5.0-macosx-static.zip&can=2&q=)

### Linux ###

* Download the [32
bit](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.6.0-linux-i686-dynamic.tar.gz&can=2&q=)
or [64
bit](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.6.0-linux-x86_64-dynamic.tar.gz&can=2&q=)
binary.
* Extract it: `sudo tar xvzf phantomjs-1.6.0-linux-*-dynamic.tar.gz -C /usr/local`
* Link it: `sudo ln -s /usr/local/phantomjs/bin/phantomjs /usr/local/bin/phantomjs`

(Note that you cannot copy the `/usr/local/phantomjs/bin/phantomjs`
binary elsewhere on its own as it dynamically links with other files in
`/usr/local/phantomjs/lib`.)

### Manual compilation ###

Do this as a last resort if the binaries don't work for you. It will
take quite a long time as it has to build WebKit.

* Download [the source tarball](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.6.0-source.tar.gz&can=2&q=)
* Extract and cd in
* `./build.sh`

## Compatibility ##

Supported: MRI 1.8.7, MRI 1.9.2, MRI 1.9.3, JRuby 1.8, JRuby 1.9.

Not supported:

* Rubinius (due to some unknown socket related issues)
* Windows

Contributions are welcome in order to move 'unsupported'
items into the 'supported' list.

## Running on a CI ##

There are no special steps to take. You don't need Xvfb or any running X
server at all.

Depending on your tests, one thing that you may need is some fonts. If
you're getting errors on a CI that don't occur during development then
try taking some screenshots - it may well be missing fonts throwing
things off kilter. Your distro will have various font packages available
to install.

[Travis CI](http://travis-ci.org/) has PhantomJS 1.5.0 installed. You may
like to use their
[chef cookbook](https://github.com/travis-ci/travis-cookbooks/tree/master/ci_environment/phantomjs)
on your own servers.

## What's supported? ##

Poltergeist supports basically everything that is supported by the stock Selenium driver,
including Javascript, drag-and-drop, etc.

There are some additional features:

### Taking screenshots ###

You can grab screenshots of the page at any point by calling
`page.driver.render('/path/to/file.png')` (this works the same way as the PhantomJS
render feature, so you can specify other extensions like `.pdf`, `.gif`, etc.)

By default, only the viewport will be rendered (the part of the page that is in view). To render
the entire page, use `page.driver.render('/path/to/file.png', :full => true)`.

### Resizing the window ###

Sometimes the window size is important to how things are rendered. Poltergeist sets the window
size to 1024x768 by default, but you can set this yourself with `page.driver.resize(width, height)`.

### Remote debugging (experimental) ###

If you use the `:inspector => true` option (see below), remote debugging
will be enabled.

When this option is enabled, you can insert `page.driver.debug` into
your tests to pause the test and launch a browser which gives you the
WebKit inspector to view your test run with.

[Read more
here](http://jonathanleighton.com/articles/2012/poltergeist-0-6-0/)

(This feature is considered experimental - it needs more polish
and [apparently will only work on
Linux until the next PhantomJS release](http://code.google.com/p/phantomjs/issues/detail?id=430).)

### Setting request headers ###

Additional HTTP request headers can be set like so:

``` ruby
page.driver.headers = {
  "Cookie" => "foo=bar",
  "Host"   => "foo.com"
}
```
They will be cleared between tests, so you do not have to do this manually.

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
*   `:debug` (Boolean) - When true, debug output is logged to `STDERR`
*   `:logger` (Object responding to `puts`) - When present, debug output is written to this object
*   `:timeout` (Numeric) - The number of seconds we'll wait for a response
    when communicating with PhantomJS. `nil` means wait forever. Default
    is 30.
*   `:inspector` (Boolean, String) - See 'Remote Debugging', above.
*   `:js_errors` (Boolean) - When false, Javascript errors do not get re-raised in Ruby.
*   `:window_size` (Array) - The dimensions of the browser window in which to test, expressed
    as a 2-element array, e.g. [1024, 768]. Default: [1024, 768]

## Setup  ##

Because Poltergeist runs your web app on a separate thread from the tests themselves, it is
essential that you ensure that your tests do not run inside transactions, or the data
you create in your tests will not be available in the web app.

Since you need to configure Capybara to avoid transactions, you will also need to tidy up
the test data you create during each test run. You can do this with 
[DatabaseCleaner](https://github.com/bmabey/database_cleaner).

First, add the `database_cleaner` gem to the `:test` group of your Gemfile.

Then, in your `test_helper.rb` file, you can do the following:

``` ruby
require 'capybara/rails'
require 'capybara/poltergeist'

# make DatabaseCleaner truncate tables 
DatabaseCleaner.strategy = :truncation

class ActionDispatch::IntegrationTest
  # make the Capybara DSL available to all integration tests
  include Capybara::DSL

  # configure Capybara to use Poltergeist for JavaScript test
  Capybara.javascript_driver = :poltergeist

  # principle of least surprise: make sure the Capybara driver is reset after each test
  teardown do
    Capybara.use_default_driver
  end
end

class JavascriptTest < ActionDispatch::IntegrationTest
  # stop ActiveRecord wrapping tests in transactions 
  self.use_transactional_fixtures = false
  
  setup do
    # tell Capybara that this is a JavaScript test
    Capybara.current_driver = Capybara.javascript_driver
  end

  teardown do
    # get rid of all the data created during the test
    DatabaseCleaner.clean
  end
end
```

Once you've got this set up correctly, you can derive your Javascript test classes from 
`JavascriptTest` and they will automatically use Poltergeist, while other integration
tests will remain unaffected.

## Bugs ##

Please file bug reports on Github and include example code to reproduce the problem wherever
possible. (Tests are even better.) Please also provide the output with
`:debug` turned on, and screenshots if you think it's relevant.

## Hacking ##

Contributions are very welcome and I will happily give commit access to
anyone who does a few good pull requests.

To get setup, run `bundle install`. You can run the full test suite with
`rspec spec/` or `rake`.

While PhantomJS is capable of compiling and running CoffeeScript code
directly, I prefer to compile the code myself and distribute that (it
makes debugging easier). Running `rake autocompile` will watch the
`.coffee` files for changes, and compile them into
`lib/capybara/client/compiled`.

## Changes ##

### 0.7.0 (unreleased) ###

#### Features ####

*   Added an option ":js_errors", allowing poltergeist to continue
    running after JS errors. (John Griffin & Tom Stuart) [Issue #62] [Issue #69]
*   Added an option ":window_size", allowing users to specify
    dimensions to which the browser window will be resized.
    (Tom Stuart) [Issue #53]
*   Capybara 1.0 is no longer supported. Capybara ~> 1.1 is required.
*   Added ability to set arbitrary http request headers

#### Bug fixes ###

*   Fix issue with `ClickFailed` exception happening with a negative
    co-ordinate (which should be impossible). (Jon Leighton, Gabriel
    Sobrinho, Tom Stuart) [Issue #60]
*   Fix issue with `undefined method map for "[]":String`, which
    happened when dealing with pages that include JS rewriting
    Array.prototype.toJSON. (Tom Stuart) [Issue #63]

### 0.6.0 ###

#### Features ####

*   Updated to PhantomJS 1.5.0, giving us proper support for reporting
    Javascript exception backtraces.

### 0.5.0 ###

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

### 0.4.0 ###

*   Element click position is now calculated using the native
    `getBoundingClientRect()` method, which will be faster and less
    buggy.

*   Handle `window.confirm()`. Always returns true, which is the same
    as capybara-webkit. [Issue #10]

*   Handle `window.prompt()`. Returns the default value, if present, or
    null.

*   Fix bug with page Javascript page loading causing problems. [Issue #19]

### 0.3.0 ###

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

### 0.2.0 ###

*   First version considered 'ready', hopefully fewer problems.

### 0.1.0 ###

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
