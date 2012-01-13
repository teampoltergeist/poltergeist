require 'capybara'

module Capybara
  module Poltergeist
    autoload :Driver,          'capybara/poltergeist/driver'
    autoload :Browser,         'capybara/poltergeist/browser'
    autoload :Node,            'capybara/poltergeist/node'
    autoload :ServerManager,   'capybara/poltergeist/server_manager'
    autoload :Server,          'capybara/poltergeist/server'
    autoload :WebSocketServer, 'capybara/poltergeist/web_socket_server'
    autoload :Client,          'capybara/poltergeist/client'

    require 'capybara/poltergeist/errors'
  end
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app)
end
