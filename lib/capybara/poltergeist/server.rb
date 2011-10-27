module Capybara::Poltergeist
  class Server
    attr_reader :port

    def initialize
      @port = find_available_port
      start
    end

    def start
      server_manager.start(port)
    end

    def restart
      server_manager.restart(port)
    end

    def send(message)
      server_manager.send(port, message)
    end

    private

    def server_manager
      ServerManager.instance
    end

    def find_available_port
      server = TCPServer.new('127.0.0.1', 0)
      server.addr[1]
    ensure
      server.close if server
    end
  end
end
