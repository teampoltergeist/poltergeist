# Poltergeist - A PhantomJS driver for Capybara #

Version: 0.1.0

Poltergeist is a driver for [Capybara](https://github.com/jnicklas/capybara). It allows you to
run your Capybara tests on a headless [WebKit](http://webkit.org) browser,
provided by [PhantomJS](http://www.phantomjs.org/).

## Installation ##

Add `poltergeist` to your Gemfile, and add in your test setup add:

    require 'capybara/poltergeist'
    Capybara.javascript_driver = :poltergeist

You will also need PhantomJS 1.3+ on your system.
[Here's how to do that](http://code.google.com/p/phantomjs/wiki/BuildInstructions).

Currently PhantomJS is not 'truly headless', so to run it on a continuous integration
server you will need to use [Xvfb](http://en.wikipedia.org/wiki/Xvfb). You can either use the
[headless gem](https://github.com/leonid-shevtsov/headless) for this,
or make sure that Xvfb is running and the `DISPLAY` environment variable is set.

## What's supported? ##

Poltergeist supports basically everything that is supported by the stock Selenium driver,
including Javascript, drag-and-drop, etc.

There are some additional features:

### Taking screenshots ###

You can grab screenshots of the page at any point by calling
`page.driver.render('/path/to/file.png')` (this works the same way as the PhantomJS
render feature, so you can specify other extensions like `.pdf`, `.gif`, etc.)

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
possible. (Tests are even better.)

## Why not use [capybara-webkit](https://github.com/thoughtbot/capybara-webkit)? ##

If capybara-webkit works for you, then by all means carry on using it.

However, I have had some trouble with it, and Poltergeist basically started
as an experiment to see whether a PhantomJS driver was possible. (It turned out it
was, but only thanks to some new features in the recent 1.3.0 release.)

In the long term, I think having a PhantomJS driver makes sense, because that allows
PhantomJS to concentrate on being an awesome headless browser, while the capybara driver
(Poltergeist) is able to be the minimal amount of glue code necessary to drive the
browser.

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
