# frozen_string_literal: true

require 'capybara'

module Capybara
  module Poltergeist
    require 'capybara/poltergeist/utility'
    require 'capybara/poltergeist/driver'
    require 'capybara/poltergeist/browser'
    require 'capybara/poltergeist/node'
    require 'capybara/poltergeist/server'
    require 'capybara/poltergeist/web_socket_server'
    require 'capybara/poltergeist/client'
    require 'capybara/poltergeist/inspector'
    require 'capybara/poltergeist/network_traffic'
    require 'capybara/poltergeist/errors'
    require 'capybara/poltergeist/cookie'
  end
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app)
end
