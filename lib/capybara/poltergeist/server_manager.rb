require 'em-websocket'
require 'timeout'
require 'singleton'

module Capybara::Poltergeist
  # The reason for the lolzy thread code is because the EM reactor blocks the thread, so
  # we have to put it in its own thread.
  #
  # The reason we are using EM, is because it has a WebSocket library. If there's a decent
  # WebSocket library that doesn't require an event loop, we can use that.
  class ServerManager
    include Singleton

    class << self
      attr_accessor :timeout
    end

    self.timeout = 30

    class TimeoutError < StandardError
      def initialize(message)
        super "Server timed out waiting for response to #{@message}"
      end
    end

    attr_reader :sockets

    def initialize
      @instruction = nil
      @response    = nil
      @sockets     = {}
      @waiting     = false

      @main   = Thread.current
      @thread = Thread.new { start_event_loop }
      @thread.abort_on_exception = true
    end

    def start(port)
      thread_execute { start_websocket_server(port) }
    end

    # This isn't a 'proper' restart. It's more like 'wait for the client to connect again'.
    def restart(port)
      sockets[port] = nil
      @thread.run
    end

    def send(port, message)
      @message = nil

      Timeout.timeout(self.class.timeout) do
        # Ensure there is a socket before trying to send a message on it.
        Thread.pass until sockets[port]

        # Send the message
        thread_execute { sockets[port].send(message) }

        # Wait for the response message
        Thread.pass until @message
      end

      @message

    rescue Timeout::Error
      raise TimeoutError.new(message)
    end

    def thread_execute(&instruction)
      # Ensure that the thread is waiting for an instruction before we wake it up
      # to receive the instruction
      Thread.pass until @waiting

      @instruction = instruction
      @waiting     = false

      # Bring the EM thread out of its sleep so that it can execute the instruction.
      @thread.run
    end

    def start_event_loop
      EM.run { await_instruction }
    end

    def start_websocket_server(port)
      EventMachine.start_server('127.0.0.1', port, EventMachine::WebSocket::Connection, {}) do |socket|
        socket.onopen do
          connection_opened(port, socket)
        end

        socket.onmessage do |message|
          message_received(message)
        end
      end
    end

    def connection_opened(port, socket)
      sockets[port] = socket
      await_instruction
    end

    def message_received(message)
      @message = message
      await_instruction
    end

    # Stop the thread so that it can be manually scheduled by the parent once there is
    # something to do
    def await_instruction
      # Sleep this thread. The main thread will wake us up when there is an instruction
      # to perform.
      @waiting = true
      Thread.stop

      # Main thread has woken us up, so execute the current instruction.
      if @instruction
        @instruction.call
        @instruction = nil
      end

      # Continue execution of the thread until a socket callback fires, which will
      # trigger then method again and send us back to sleep.
    end
  end
end
