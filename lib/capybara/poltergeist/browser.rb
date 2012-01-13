require 'json'

module Capybara::Poltergeist
  class Browser
    attr_reader :options, :server, :client

    DEFAULT_TIMEOUT = 10

    def initialize(options = {})
      @options = options
      @server  = Server.new(options.fetch(:timeout, DEFAULT_TIMEOUT))
      @client  = Client.new(server.port, options[:phantomjs])
    end

    def timeout
      server.timeout
    end

    def timeout=(sec)
      server.timeout = sec
    end

    def restart
      server.restart
      client.restart
    end

    def visit(url, attributes = {})
      command 'visit', url
    end

    def current_url
      command 'current_url'
    end

    def body
      command 'body'
    end

    def source
      command 'source'
    end

    def find(selector, id = nil)
      command 'find', selector, id
    end

    def text(id)
      command 'text', id
    end

    def attribute(id, name)
      command 'attribute', id, name
    end

    def value(id)
      command 'value', id
    end

    def set(id, value)
      command 'set', id, value
    end

    def select_file(id, value)
      command 'select_file', id, value
    end

    def tag_name(id)
      command('tag_name', id).downcase
    end

    def visible?(id)
      command 'visible', id
    end

    def evaluate(script)
      command 'evaluate', script
    end

    def execute(script)
      command 'execute', script
    end

    def within_frame(id, &block)
      command 'push_frame', id
      yield
      command 'pop_frame'
    end

    def reset
      visit('about:blank')
    end

    def click(id)
      command 'click', id
    end

    def drag(id, other_id)
      command 'drag', id, other_id
    end

    def select(id, value)
      command 'select', id, value
    end

    def trigger(id, event)
      command 'trigger', id, event
    end

    def reset
      command 'reset'
    end

    def render(path, options = {})
      command 'render', path, !!options[:full]
    end

    def resize(width, height)
      command 'resize', width, height
    end

    def logger
      options[:logger]
    end

    def log(message)
      logger.puts message if logger
    end

    def command(name, *args)
      message = { 'name' => name, 'args' => args }
      log message.inspect

      json = JSON.parse(server.send(JSON.generate(message)))
      log json.inspect

      if json['error']
        raise BrowserError.new(json['error'])
      else
        json['response']
      end

    rescue DeadClient
      restart
      raise
    end
  end
end
