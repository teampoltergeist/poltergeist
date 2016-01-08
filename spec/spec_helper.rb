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
  options = {
    logger: TestSessions.logger,
    inspector: debug,
    debug: debug
  }

  options[:phantomjs] = ENV['PHANTOMJS'] if ENV['TRAVIS'] && ENV['PHANTOMJS']

  Capybara::Poltergeist::Driver.new(
    app, options
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

RSpec::Expectations.configuration.warn_about_potential_false_positives = false if ENV['TRAVIS']

RSpec.configure do |config|
  config.before do
    TestSessions.logger.reset
  end

  config.after do |example|
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

  [:js, :modals, :windows].each do |cond|
    config.before(:each, :requires => cond) do
      Poltergeist::SpecHelper.set_capybara_wait_time(1)
    end
  end
end
