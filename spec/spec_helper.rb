$:.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'bundler/setup'

require 'rspec'
require 'capybara/poltergeist'

RSpec.configure do |config|
  config.before do
    Capybara.configure do |config|
      config.default_selector = :xpath
    end
  end
end

require 'capybara/spec/driver'
require 'capybara/spec/session'
require 'support/test_app'

Capybara.default_wait_time = 0 # less timeout so tests run faster

alias :running :lambda

if ENV['DEBUG']
  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app, :debug => true)
  end
end

module TestSessions
  Poltergeist = Capybara::Session.new(:poltergeist, TestApp)
end
