module Capybara::Poltergeist
  class Server
    attr_reader :port, :socket, :timeout

    def initialize(timeout = nil)
      @port    = find_available_port
      @timeout = timeout
      start
    end

    def timeout=(sec)
      @timeout = @socket.timeout = sec
    end

    def start
      @socket = WebSocketServer.new(port, timeout)
    end

    def restart
      @socket.close
      @socket = WebSocketServer.new(port, timeout)
    end

    def send(message)
      @socket.send(message) or raise DeadClient.new(message)
    end

    private

    def find_available_port
      server = TCPServer.new('127.0.0.1', 0)
      server.addr[1]
    ensure
      server.close if server
    end
  end
end
