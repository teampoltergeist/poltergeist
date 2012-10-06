module Capybara::Poltergeist
  class Server
    attr_reader :port, :socket, :timeout

    def initialize(port, timeout = nil)
      @port    = port
      @timeout = timeout
      start
    end

    def timeout=(sec)
      @timeout = @socket.timeout = sec
    end

    def start
      @socket = WebSocketServer.new(port, timeout)
    end

    def stop
      @socket.close
    end

    def restart
      stop
      start
    end

    def send(message)
      @socket.send(message) or raise DeadClient.new(message)
    end
  end
end
