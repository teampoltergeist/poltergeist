require 'socket'
require 'stringio'
require 'http/parser'
require 'faye/websocket'

module Capybara::Poltergeist
  # This is a 'custom' Web Socket server that is designed to be synchronous. What
  # this means is that it sends a message, and then waits for a response. It does
  # not expect to receive a message at any other time than right after it has sent
  # a message. So it is basically operating a request/response cycle (which is not
  # how Web Sockets are usually used, but it's what we want here, as we want to
  # send a message to PhantomJS and then wait for it to respond).
  class WebSocketServer
    class FayeHandler
      attr_reader :owner, :env, :parser

      def initialize(owner, env)
        @owner    = owner
        @env      = env
        @parser   = Faye::WebSocket.parser(env).new(self)
        @messages = []
      end

      def url
        "ws://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}/"
      end

      def handshake_response
        parser.handshake_response
      end

      def parse(data)
        parser.parse(data)
      end

      def encode(message)
        parser.frame(Faye::WebSocket.encode(message))
      end

      def receive(message)
        @messages << message
      end

      def message?
        @messages.any?
      end

      def next_message
        @messages.shift
      end
    end

    # How much to try to read from the socket at once (it's kinda arbitrary because we
    # just keep reading until we've received a full frame)
    RECV_SIZE = 1024

    attr_reader :port, :parser, :socket, :handler, :server
    attr_accessor :timeout

    def initialize(port, timeout = nil)
      @port    = port
      @parser  = Http::Parser.new
      @server  = TCPServer.open(port)
      @timeout = timeout
    end

    def connected?
      !socket.nil?
    end

    # Accept a client on the TCP server socket, then receive its initial HTTP request
    # and use that to initialize a Web Socket.
    def accept
      @socket = server.accept

      while msg = socket.gets
        parser << msg
        break if msg == "\r\n"
      end

      @handler = FayeHandler.new(self, env)
      socket.write handler.handshake_response
    end

    # Note that the socket.read(8) assumes we're using the hixie-76 parser. This is
    # fine for now as it corresponds to the version of Web Sockets that the version of
    # WebKit in PhantomJS uses, but it might need to change in the future.
    def env
      @env ||= begin
        env = {
          'REQUEST_METHOD' => parser.http_method,
          'SCRIPT_NAME'    => '',
          'PATH_INFO'      => '',
          'QUERY_STRING'   => '',
          'SERVER_NAME'    => '127.0.0.1',
          'SERVER_PORT'    => port.to_s,
          'HTTP_ORIGIN'    => 'http://127.0.0.1:2000/',
          'rack.input'     => StringIO.new(socket.read(8))
        }
        parser.headers.each do |header, value|
          env['HTTP_' + header.upcase.gsub('-', '_')] = value
        end
        env
      end
    end

    # Block until the next message is available from the Web Socket
    def receive
      until handler.message?
        IO.select([socket], [], [], timeout)
        data = socket.recv_nonblock(RECV_SIZE)
        break if data.empty?
        handler.parse(data)
      end

      handler.next_message
    end

    # Send a message and block until there is a response
    def send(message)
      accept unless connected?
      socket.write handler.encode(message)
      receive
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
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
