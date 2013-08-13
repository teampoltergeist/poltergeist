Contributions are very welcome. If you want a feature to be added,
chances are it will not happen unless you actually write the code.

# Set Up

To get setup, run `bundle install`.  You
can run the full test suite with `rspec spec/` or `rake`.

# Reporting a bug:

Help us help you :smile:! The more information you can provide in your
github issue, the better; the very *best* way to report a bug is to submit
a pull-request that shows off the bug you're seeing, and describes both the
*expected* and *actual* behaviors in as much relevant detail as possible,
as well as the steps you've taken to isolate the issue so far.

# Add a Feature; fix a Bug

All pull requests which add a feature or fix a bug must have the
following things:

* Integration test(s). These generally go into
  `spec/integration/session_spec.rb`, unless it's something specific to
  the driver, in which case it goes in `spec/integration/driver_spec.rb`.
  (So a test for `page.driver.resize` goes in `driver_spec.rb` but a test
  for `page.execute_script` goes in `session_spec.rb`.)
* A [good commit
  message](https://github.com/blog/926-shiny-new-commit-styles)
* An entry into the changelog. Reference the Github issue number if there is an
  associated bug report. Feel free to add your name if you want to be
  credited.

# Keep in mind:

* While PhantomJS is capable of compiling and running CoffeeScript code
  directly, I prefer to compile the code myself and distribute that (it
  makes debugging easier). Running `rake autocompile` will watch the
  `.coffee` files for changes, and compile them into
  `lib/capybara/client/compiled`.
* If you've worked on your changes over time, please squash the commits
  in a sensible manner so that each commit is self-contained. If you
  need to update a pull request with new changes, you can just `git push
  -f` to your branch which will overwrite previous commits that you have
  now squashed.
* Please try to pay attention to and follow the existing coding style.

Thanks! It's really great when people help with Poltergeist's
development.
