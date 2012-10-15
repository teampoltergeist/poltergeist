require 'socket'

module Capybara::Poltergeist
  module Util
    def self.find_available_port
      server = TCPServer.new('127.0.0.1', 0)
      server.addr[1]
    ensure
      server.close if server
    end
  end
end
