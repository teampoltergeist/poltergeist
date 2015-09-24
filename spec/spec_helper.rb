POLTERGEIST_ROOT = File.expand_path('../..', __FILE__)
$:.unshift(POLTERGEIST_ROOT + '/lib')

require 'bundler/setup'

require 'rspec'
require 'capybara/spec/spec_helper'
require 'capybara/poltergeist'

require 'support/test_app'
require 'support/spec_logger'

Capybara.register_driver :poltergeist do |app|
  debug = !ENV['DEBUG'].nil?
  Capybara::Poltergeist::Driver.new(
    app, logger: TestSessions.logger, inspector: debug, debug: debug
  )
end

module TestSessions
  def self.logger
    @logger ||= SpecLogger.new
  end

  Poltergeist = Capybara::Session.new(:poltergeist, TestApp)
end

module Poltergeist
  module SpecHelper
    class << self
      def set_capybara_wait_time(t)
        Capybara.default_max_wait_time = t
      rescue
        Capybara.default_wait_time = t
      end
    end
  end
end

RSpec.configure do |config|
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

  Capybara::SpecHelper.configure(config)

  config.before(:each) do
    Poltergeist::SpecHelper.set_capybara_wait_time(0)
  end

  config.before(:each, :requires => :js) do
    Poltergeist::SpecHelper.set_capybara_wait_time(1)
  end
end
