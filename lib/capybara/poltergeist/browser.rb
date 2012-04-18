require 'multi_json'

module Capybara::Poltergeist
  class Browser
    attr_reader :server, :client, :logger

    def initialize(server, client, logger = nil)
      @server = server
      @client = client
      @logger = logger
    end

    def restart
      server.restart
      client.restart
    end

    def visit(url)
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

    def find(selector)
      result = command('find', selector)
      result['ids'].map { |id| [result['page_id'], id] }
    end

    def find_within(page_id, id, selector)
      command 'find_within', page_id, id, selector
    end

    def text(page_id, id)
      command 'text', page_id, id
    end

    def attribute(page_id, id, name)
      command 'attribute', page_id, id, name.to_s
    end

    def value(page_id, id)
      command 'value', page_id, id
    end

    def set(page_id, id, value)
      command 'set', page_id, id, value
    end

    def select_file(page_id, id, value)
      command 'select_file', page_id, id, value
    end

    def tag_name(page_id, id)
      command('tag_name', page_id, id).downcase
    end

    def visible?(page_id, id)
      command 'visible', page_id, id
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

    def click(page_id, id)
      command 'click', page_id, id
    end

    def drag(page_id, id, other_id)
      command 'drag', page_id, id, other_id
    end

    def select(page_id, id, value)
      command 'select', page_id, id, value
    end

    def trigger(page_id, id, event)
      command 'trigger', page_id, id, event.to_s
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

    def command(name, *args)
      message = { 'name' => name, 'args' => args }
      log message.inspect

      json = MultiJson.load(server.send(MultiJson.dump(message)))
      log json.inspect

      if json['error']
        if json['error']['name'] == 'Poltergeist.JavascriptError'
          raise JavascriptError.new(json['error'])
        else
          raise BrowserError.new(json['error'])
        end
      else
        json['response']
      end

    rescue DeadClient
      restart
      raise
    end

    private

    def log(message)
      logger.puts message if logger
    end
  end
end
