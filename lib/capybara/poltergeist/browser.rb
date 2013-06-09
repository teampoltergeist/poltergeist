require "capybara/poltergeist/errors"
require 'multi_json'
require 'time'

module Capybara::Poltergeist
  class Browser
    ERROR_MAPPINGS = {
      "Poltergeist.JavascriptError" => JavascriptError,
      "Poltergeist.FrameNotFound"   => FrameNotFound,
      "Poltergeist.InvalidSelector" => InvalidSelector
    }

    attr_reader :server, :client, :logger

    def initialize(server, client, logger = nil)
      @server = server
      @client = client
      @logger = logger
    end

    def restart
      server.restart
      client.restart

      self.debug = @debug if @debug
    end

    def visit(url)
      command 'visit', url
    end

    def current_url
      command 'current_url'
    end

    def status_code
      command 'status_code'
    end

    def body
      command 'body'
    end

    def source
      command 'source'
    end

    def title
      command 'title'
    end

    def find(method, selector)
      result = command('find', method, selector)
      result['ids'].map { |id| [result['page_id'], id] }
    end

    def find_within(page_id, id, method, selector)
      command 'find_within', page_id, id, method, selector
    end

    def all_text(page_id, id)
      command 'all_text', page_id, id
    end

    def visible_text(page_id, id)
      command 'visible_text', page_id, id
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

    def disabled?(page_id, id)
      command 'disabled', page_id, id
    end

    def click_coordinates(x, y)
      command 'click_coordinates', x, y
    end

    def evaluate(script)
      command 'evaluate', script
    end

    def execute(script)
      command 'execute', script
    end

    def within_frame(handle, &block)
      if handle.is_a?(Capybara::Node::Base)
        command 'push_frame', handle['id']
      else
        command 'push_frame', handle
      end

      yield
    ensure
      command 'pop_frame'
    end

    def within_window(name, &block)
      command 'push_window', name
      yield
    ensure
      command 'pop_window'
    end

    def click(page_id, id)
      command 'click', page_id, id
    end

    def double_click(page_id, id)
      command 'double_click', page_id, id
    end

    def hover(page_id, id)
      command 'hover', page_id, id
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
      command 'render', path.to_s, !!options[:full]
    end

    def resize(width, height)
      command 'resize', width, height
    end

    def network_traffic
      command('network_traffic').values.map do |event|
        NetworkTraffic::Request.new(
          event['request'],
          event['responseParts'].map { |response| NetworkTraffic::Response.new(response) }
        )
      end
    end

    def equals(page_id, id, other_id)
      command('equals', page_id, id, other_id)
    end

    def set_headers(headers)
      command 'set_headers', headers
    end

    def response_headers
      command 'response_headers'
    end

    def cookies
      Hash[command('cookies').map { |cookie| [cookie['name'], Cookie.new(cookie)] }]
    end

    def set_cookie(cookie)
      if cookie[:expires]
        cookie[:expires] = cookie[:expires].to_i * 1000
      end

      command 'set_cookie', cookie
    end

    def remove_cookie(name)
      command 'remove_cookie', name
    end

    def cookies_enabled=(flag)
      command 'cookies_enabled', !!flag
    end

    def js_errors=(val)
      command 'set_js_errors', !!val
    end

    def extensions=(names)
      Array(names).each do |name|
        command 'add_extension', name
      end
    end

    def debug=(val)
      @debug = val
      command 'set_debug', !!val
    end

    def command(name, *args)
      message = { 'name' => name, 'args' => args }
      log message.inspect

      json = JSON.load(server.send(JSON.dump(message)))
      log json.inspect

      if json['error']
        klass = ERROR_MAPPINGS[json['error']['name']] || BrowserError
        raise klass.new(json['error'])
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
