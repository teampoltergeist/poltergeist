# Poltergeist - A PhantomJS driver for Capybara #

Version: 0.1.0

Poltergeist is a driver for [Capybara](https://github.com/jnicklas/capybara). It allows you to
run your Capybara tests on a headless [WebKit](http://webkit.org) browser,
provided by [PhantomJS](http://www.phantomjs.org/).

## Installation ##

Add `poltergeist` to your Gemfile, and add in your test setup add:

    require 'capybara/poltergeist'
    Capybara.javascript_driver = :poltergeist

Currently PhantomJS is not 'truly headless', so to run it on a continuous integration
server you will need to use [Xvfb](http://en.wikipedia.org/wiki/Xvfb). You can either use the
[headless gem](https://github.com/leonid-shevtsov/headless) for this,
or make sure that Xvfb is running and the `DISPLAY` environment variable is set.

## Installing PhantomJS ##

You need PhantomJS 1.4.1+, built against Qt 4.8, on your system.

### Mac users ##

By far the easiest, most reliable thing to do is to [install the
pre-built static binary](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.4.1-macosx-static-x86.zip&can=2&q=).
Try this first.

### Linux users, or if the pre-built Mac binary doesn't work ###

You need to build PhantomJS manually. Unfortunately, this not
currently straightforward, for two reasons:

1. Using Poltergeist with PhantomJS built against Qt 4.7 causes
   segfaults in WebKit's Javascript engine. Fortunately, this problem
   doesn't occur under the recently released Qt 4.8. But if you don't
   have Qt 4.8 on your system (check with `qmake --version`), you'll
   need to build it.

2. A change in the version of WebKit bundled with Qt 4.8 means that in order
   to be able to attach files to file `<input>` elements, we must apply
   a patch to the Qt source tree that PhantomJS is built against.

So, you basically have two options:

1. **If you have Qt 4.8 on your system, and don't need to use file
   inputs**, [follow the standard PhantomJS build instructions](http://code.google.com/p/phantomjs/wiki/BuildInstructions).

2. **Otherwise**, [download the PhantomJS tarball](http://code.google.com/p/phantomjs/downloads/detail?name=phantomjs-1.4.1-source.tar.gz&can=2&q=),
   `cd deploy/` and run either `./build-linux.sh --qt-4.8` or `./build-mac.sh`.
   The script will
   download Qt, apply some patches, build it, and then build PhantomJS
   against the patched build of Qt. It takes quite a while, around 30
   minutes on a modern computer with two hyperthreaded cores. Afterwards,
   you should copy the `bin/phantomjs` binary into your `PATH`.

PhantomJS 1.5 plans to bundle a stripped-down version of Qt, which will
reduce the build time a bit (although most of the time is spent building
WebKit) and make it easier to apply patches. When it is possible to make
static builds for Linux, those may be provided too, so most users will
avoid having to build it themselves.

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

## Customization ##

You can customize the way that Capybara sets up Poltegeist via the following code in your
test setup:

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, options)
    end

`options` is a hash of options. The following options are supported:

  * `:phantomjs` (String) - A custom path to the phantomjs executable
  * `:debug` (Boolean) - When true, debug output is logged to `STDERR`
  * `:logger` (Object responding to `puts`) - When present, debug output is written to this object

## Bugs ##

Please file bug reports on Github and include example code to reproduce the problem wherever
possible. (Tests are even better.) Please also provide the output with
`:debug` turned on, and screenshots if you think it's relevant.

## Why not use [capybara-webkit](https://github.com/thoughtbot/capybara-webkit)? ##

If capybara-webkit works for you, then by all means carry on using it.

However, I have had some trouble with it, and Poltergeist basically started
as an experiment to see whether a PhantomJS driver was possible. (It turned out it
was, but only thanks to some new features since the 1.3 release.)

In the long term, I think having a PhantomJS driver makes sense, because that allows
PhantomJS to concentrate on being an awesome headless browser, while the capybara driver
(Poltergeist) is able to be the minimal amount of glue code necessary to drive the
browser.

I also find it more pleasant to hack in CoffeeScript than C++,
particularly as my C++ experience only goes as far as trying to make
PhantomJS/Qt/WebKit work with Poltergeist :)

## Hacking ##

Contributions are very welcome and I will happily give commit access to
anyone who does a few good pull requests.

To get setup, run `bundle install`. You can run the full test suite with
`rspec spec/` or `rake`.

I previously set up the repository on [Travis CI](http://travis-ci.org/)
but unfortunately given they need a custom-built Qt+PhantomJS in order
to pass, it can't be used for now. When static Linux PhantomJS builds
are working this can be revisited.

While PhantomJS is capable of compiling and running CoffeeScript code
directly, I prefer to compile the code myself and distribute that (it
makes debugging easier). Running `rake autocompile` will watch the
`.coffee` files for changes, and compile them into
`lib/capybara/client/compiled`.

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
