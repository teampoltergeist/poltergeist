POLTERGEIST_ROOT = File.expand_path('../..', __FILE__)
$:.unshift(POLTERGEIST_ROOT + '/lib')

require 'bundler/setup'

require 'rspec'
require 'capybara/poltergeist'

require 'support/test_app'
require 'support/spec_logger'

Capybara.default_wait_time = 0 # less timeout so tests run faster

alias :running :lambda

logger = SpecLogger.new

Capybara.register_driver :poltergeist do |app|
  opts = { :logger => logger }
  opts[:phantomjs] = "/home/vagrant/builds/jonleighton/poltergeist/phantomjs/bin/phantomjs" if ENV['TRAVIS']
  Capybara::Poltergeist::Driver.new(app, opts)
end

module TestSessions
  Poltergeist = Capybara::Session.new(:poltergeist, TestApp)
end

RSpec.configure do |config|
  config.before do
    Capybara.configure do |config|
      config.default_selector = :xpath
    end
  end

  config.before do
    logger.reset
  end

  config.after do |*args|
    if ENV['DEBUG']
      puts logger.messages
    elsif ENV['TRAVIS'] && example.exception
      example.exception.message << "\n\nDebug info:\n" + logger.messages.join("\n")
    end
  end
end
