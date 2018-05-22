# frozen_string_literal: true

POLTERGEIST_ROOT = File.expand_path('..', __dir__)
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
      rescue StandardError
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
      example.exception.message << "\n\nDebug info:\n" + TestSessions.logger.messages.join("\n") unless example.exception.message.frozen?
    end
  end

  Capybara::SpecHelper.configure(config)

  config.filter_run_excluding full_description: lambda { |description, _metadata|
    [
      # test is marked pending in Capybara but Poltergeist passes - disable here - have our own test in driver spec
      /Capybara::Session Poltergeist node #set should allow me to change the contents of a contenteditable elements child/,
      # should not pass because PhantomJS doesn't support datalist
      /Capybara::Session Poltergeist #select input with datalist/
    ].any? { |desc| description =~ desc }
  }

  config.before(:each) do
    Poltergeist::SpecHelper.set_capybara_wait_time(0)
  end

  %i[js modals windows].each do |cond|
    config.before(:each, requires: cond) do
      Poltergeist::SpecHelper.set_capybara_wait_time(1)
    end
  end
end

def phantom_version_is?(ver_spec, driver)
  Cliver.detect(driver.options[:phantomjs] || Capybara::Poltergeist::Client::PHANTOMJS_NAME, ver_spec)
end
