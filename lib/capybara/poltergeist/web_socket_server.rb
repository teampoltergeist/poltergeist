require 'socket'
require 'websocket/driver'

module Capybara::Poltergeist
  # This is a 'custom' Web Socket server that is designed to be synchronous. What
  # this means is that it sends a message, and then waits for a response. It does
  # not expect to receive a message at any other time than right after it has sent
  # a message. So it is basically operating a request/response cycle (which is not
  # how Web Sockets are usually used, but it's what we want here, as we want to
  # send a message to PhantomJS and then wait for it to respond).
  class WebSocketServer
    # How much to try to read from the socket at once (it's kinda arbitrary because we
    # just keep reading until we've received a full frame)
    RECV_SIZE = 1024

    # How many seconds to try to bind to the port for before failing
    BIND_TIMEOUT = 5

    HOST = '127.0.0.1'

    attr_reader :port, :driver, :socket, :server
    attr_accessor :timeout

    def initialize(port = nil, timeout = nil)
      @timeout = timeout
      @server  = start_server(port)
    end

    def port
      server.addr[1]
    end

    def start_server(port)
      time = Time.now

      begin
        TCPServer.open(HOST, port || 0)
      rescue Errno::EADDRINUSE
        if (Time.now - time) < BIND_TIMEOUT
          sleep(0.01)
          retry
        else
          raise
        end
      end
    end

    def connected?
      !socket.nil?
    end

    # Accept a client on the TCP server socket, then receive its initial HTTP request
    # and use that to initialize a Web Socket.
    def accept
      @socket   = server.accept
      @messages = []

      @driver = ::WebSocket::Driver.server(self)
      @driver.on(:connect) { |event| @driver.start }
      @driver.on(:message) { |event| @messages << event.data }
    end

    def write(data)
      @socket.write(data)
    end

    # Block until the next message is available from the Web Socket.
    # Raises Errno::EWOULDBLOCK if timeout is reached.
    def receive
      start = Time.now

      until @messages.any?
        raise Errno::EWOULDBLOCK if (Time.now - start) >= timeout
        IO.select([socket], [], [], timeout) or raise Errno::EWOULDBLOCK
        data = socket.recv(RECV_SIZE)
        break if data.empty?
        driver.parse(data)
      end

      @messages.shift
    end

    # Send a message and block until there is a response
    def send(message)
      accept unless connected?
      driver.text(message)
      receive
    rescue Errno::EWOULDBLOCK
      raise TimeoutError.new(message)
    end

    def close
      [server, socket].compact.each do |s|
        s.close_read
        s.close_write
      end
    end
  end
end
