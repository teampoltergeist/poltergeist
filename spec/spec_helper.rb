POLTERGEIST_ROOT = File.expand_path('../..', __FILE__)
$:.unshift(POLTERGEIST_ROOT + '/lib')

require 'bundler/setup'

require 'rspec'
require 'capybara/poltergeist'

require 'support/test_app'
require 'support/spec_logger'

Capybara.default_wait_time = 0 # less timeout so tests run faster
Capybara.server_boot_timeout = 30 # provide a little extra start-up time on slower systems

alias :running :lambda


Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(
    app,
    :logger    => TestSessions.logger,
    :inspector => (ENV['DEBUG'] != nil)
  )
end

module TestSessions
  def self.logger
    @logger ||= SpecLogger.new
  end

  Poltergeist = Capybara::Session.new(:poltergeist, TestApp)
end

RSpec.configure do |config|
  config.before do
    Capybara.configure do |config|
      config.default_selector = :xpath
    end
  end

  config.before do
    TestSessions.logger.reset
  end

  config.after do
    if ENV['DEBUG']
      puts TestSessions.logger.messages
    elsif ENV['TRAVIS'] && example.exception
      example.exception.message << "\n\nDebug info:\n" + TestSessions.logger.messages.join("\n")
    end
  end
end
