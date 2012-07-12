module Capybara::Poltergeist
  module NetworkTraffic
    autoload :Request,  'capybara/poltergeist/network_traffic/request'
    autoload :Response, 'capybara/poltergeist/network_traffic/response'
  end
end
