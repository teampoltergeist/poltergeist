# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'capybara/poltergeist/version'

Gem::Specification.new do |s|
  s.name        = "poltergeist"
  s.version     = Capybara::Poltergeist::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jon Leighton"]
  s.email       = ["j@jonathanleighton.com"]
  s.homepage    = "http://github.com/jonleighton/poltergeist"
  s.summary     = "PhantomJS driver for Capybara"
  s.description = "PhantomJS driver for Capybara"

  s.add_dependency "capybara",       "~> 1.1"
  s.add_dependency "multi_json",     "~> 1.0"
  s.add_dependency "childprocess",   "~> 0.3"
  s.add_dependency "http_parser.rb", "~> 0.5.3"
  s.add_dependency "faye-websocket", "~> 0.4.4"

  s.add_development_dependency 'rspec',              '~> 2.8'
  s.add_development_dependency 'sinatra',            '~> 1.0'
  s.add_development_dependency 'rake',               '~> 0.9.2'
  s.add_development_dependency 'image_size',         '~> 1.0'
  s.add_development_dependency 'coffee-script',      '~> 2.2.0'
  s.add_development_dependency 'guard-coffeescript', '~> 1.0.0'
  s.add_development_dependency 'rspec-rerun',        '~> 0.1'

  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.md)
  s.require_path = 'lib'
end
