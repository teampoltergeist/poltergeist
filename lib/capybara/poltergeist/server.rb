# frozen_string_literal: true

module Capybara::Poltergeist
  class Server
    attr_reader :socket, :fixed_port, :timeout, :custom_host

    def initialize(fixed_port = nil, timeout = nil, custom_host = nil)
      @fixed_port = fixed_port
      @timeout    = timeout
      @custom_host = custom_host
      start
    end

    def port
      @socket.port
    end

    def host
      @socket.host
    end

    def timeout=(sec)
      @timeout = @socket.timeout = sec
    end

    def start
      @socket = WebSocketServer.new(fixed_port, timeout, custom_host)
    end

    def stop
      @socket.close
    end

    def restart
      stop
      start
    end

    def send(command)
      receive_timeout = nil # default
      if command.name == 'visit'
        command.args.push(timeout) # set the client set visit timeout parameter
        receive_timeout = timeout + 5 # Add a couple of seconds to let the client timeout first
      end
      @socket.send(command.id, command.message, receive_timeout) or raise DeadClient.new(command.message)
    end
  end
end
