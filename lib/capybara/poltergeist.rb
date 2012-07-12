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
    autoload :Util,            'capybara/poltergeist/util'
    autoload :Inspector,       'capybara/poltergeist/inspector'
    autoload :Spawn,           'capybara/poltergeist/spawn'
    autoload :JSON,            'capybara/poltergeist/json'
    autoload :NetworkTraffic,  'capybara/poltergeist/network_traffic'

    require 'capybara/poltergeist/errors'
  end
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app)
end
