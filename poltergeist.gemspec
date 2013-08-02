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

  s.required_ruby_version = ">= 1.9.2"

  s.add_dependency "capybara",         "~> 2.1.0"
  s.add_dependency "websocket-driver", ">= 0.2.0"
  s.add_dependency "multi_json",       "~> 1.0"
  s.add_dependency "cliver",           "~> 0.2.1"

  s.add_development_dependency 'rspec',              '~> 2.12'
  s.add_development_dependency 'sinatra',            '~> 1.0'
  s.add_development_dependency 'rake',               '~> 10.0'
  s.add_development_dependency 'image_size',         '~> 1.0'
  s.add_development_dependency 'coffee-script',      '~> 2.2.0'
  s.add_development_dependency 'guard-coffeescript', '~> 1.0.0'
  s.add_development_dependency 'rspec-rerun',        '~> 0.1'

  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.md)
  s.require_path = 'lib'
end
