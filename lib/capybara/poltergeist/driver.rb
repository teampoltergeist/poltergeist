require 'uri'

module Capybara::Poltergeist
  class Driver < Capybara::Driver::Base
    DEFAULT_TIMEOUT = 30

    attr_reader :app, :app_server, :server, :client, :browser, :options

    def initialize(app, options = {})
      @app       = app
      @options   = options
      @browser   = nil
      @inspector = nil
      @server    = nil
      @client    = nil

      @app_server = Capybara::Server.new(app)
      @app_server.boot if Capybara.run_server
    end

    def browser
      @browser ||= Browser.new(server, client, logger, js_errors)
    end

    def inspector
      @inspector ||= options[:inspector] && Inspector.new(options[:inspector])
    end

    def server
      @server ||= Server.new(
        options.fetch(:port)    { Util.find_available_port },
        options.fetch(:timeout) { DEFAULT_TIMEOUT          }
      )
    end

    def client
      @client ||= Client.start(server.port,
        :path              => options[:phantomjs],
        :window_size       => options[:window_size],
        :phantomjs_options => phantomjs_options
      )
    end

    def phantomjs_options
      list = options[:phantomjs_options] || []
      list += ["--remote-debugger-port=#{inspector.port}", "--remote-debugger-autorun=yes"] if inspector
      list
    end

    def client_pid
      client.pid
    end

    def timeout
      server.timeout
    end

    def timeout=(sec)
      server.timeout = sec
    end

    def restart
      browser.restart
    end

    def quit
      server.stop
      client.stop
    end

    # logger should be an object that responds to puts, or nil
    def logger
      options[:logger] || (options[:debug] && STDERR)
    end

    def js_errors
      options.fetch(:js_errors, true)
    end

    def visit(path)
      browser.visit app_server.url(path)
    end

    def current_url
      browser.current_url
    end

    def status_code
      browser.status_code
    end

    def body
      browser.body
    end

    def source
      browser.source.to_s
    end

    def find(selector)
      browser.find(selector).map { |page_id, id| Capybara::Poltergeist::Node.new(self, page_id, id) }
    end

    def evaluate_script(script)
      browser.evaluate(script)
    end

    def execute_script(script)
      browser.execute(script)
      nil
    end

    def within_frame(name, &block)
      browser.within_frame(name, &block)
    end

    def within_window(name, &block)
      browser.within_window(name, &block)
    end

    def reset!
      browser.reset
    end

    def render(path, options = {})
      browser.render(path, options)
    end

    def resize(width, height)
      browser.resize(width, height)
    end
    alias_method :resize_window, :resize

    def network_traffic
      browser.network_traffic
    end

    def headers=(headers)
      browser.set_headers(headers)
    end

    def response_headers
      browser.response_headers
    end

    def cookies
      browser.cookies
    end

    def set_cookie(name, value, options = {})
      browser.set_cookie({
        :name   => name,
        :value  => value,
        :domain => URI.parse(app_server.url('')).host
      }.merge(options))
    end

    def remove_cookie(name)
      browser.remove_cookie(name)
    end

    def debug
      if @options[:inspector]
        inspector.open
        pause
      else
        raise Error, "To use the remote debugging, you have to launch the driver " \
                     "with `:inspector => true` configuration option"
      end
    end

    def pause
      STDERR.puts "Poltergeist execution paused. Press enter to continue."
      STDIN.gets
    end

    def wait?
      true
    end

    def invalid_element_errors
      [Capybara::Poltergeist::ObsoleteNode, Capybara::Poltergeist::ClickFailed]
    end
  end
end
