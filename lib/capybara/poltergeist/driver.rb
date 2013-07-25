require 'uri'

module Capybara::Poltergeist
  class Driver < Capybara::Driver::Base
    DEFAULT_TIMEOUT = 30

    attr_reader :app, :server, :client, :browser, :options

    def initialize(app, options = {})
      @app       = app
      @options   = options
      @browser   = nil
      @inspector = nil
      @server    = nil
      @client    = nil
      @started   = false
    end

    def needs_server?
      true
    end

    def browser
      @browser ||= begin
        browser = Browser.new(server, client, logger)
        browser.js_errors  = options[:js_errors] if options.key?(:js_errors)
        browser.extensions = options.fetch(:extensions, [])
        browser.debug      = true if options[:debug]
        browser
      end
    end

    def inspector
      @inspector ||= options[:inspector] && Inspector.new(options[:inspector])
    end

    def server
      @server ||= Server.new(options[:port], options.fetch(:timeout) { DEFAULT_TIMEOUT })
    end

    def client
      @client ||= Client.start(server,
        :path              => options[:phantomjs],
        :window_size       => options[:window_size],
        :phantomjs_options => phantomjs_options,
        :phantomjs_logger  => phantomjs_logger
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

    # logger should be an object that behaves like IO or nil
    def phantomjs_logger
      options.fetch(:phantomjs_logger, nil)
    end

    def visit(url)
      @started = true
      browser.visit(url)
    end

    def current_url
      browser.current_url
    end

    def status_code
      browser.status_code
    end

    def html
      browser.body
    end
    alias_method :body, :html

    def source
      browser.source.to_s
    end

    def title
      browser.title
    end

    def find(method, selector)
      browser.find(method, selector).map { |page_id, id| Capybara::Poltergeist::Node.new(self, page_id, id) }
    end

    def find_xpath(selector)
      find :xpath, selector
    end

    def find_css(selector)
      find :css, selector
    end

    def click(x, y)
      browser.click_coordinates(x, y)
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

    def window_handles
      browser.window_handles
    end

    def reset!
      browser.reset
      @started = false
    end

    def save_screenshot(path, options = {})
      browser.render(path, options)
    end
    alias_method :render, :save_screenshot

    def resize(width, height)
      browser.resize(width, height)
    end
    alias_method :resize_window, :resize

    def network_traffic
      browser.network_traffic
    end

    def headers
      browser.get_headers
    end

    def headers=(headers)
      browser.set_headers(headers)
    end

    def add_headers(headers)
      browser.add_headers(headers)
    end

    def add_header(name, value, options = {})
      permanent = options.fetch(:permanent, true)
      browser.add_header({ name => value }, permanent)
    end

    def response_headers
      browser.response_headers
    end

    def cookies
      browser.cookies
    end

    def set_cookie(name, value, options = {})
      options[:name]  ||= name
      options[:value] ||= value
      options[:domain] ||= begin
        if @started
          URI.parse(URI.escape(browser.current_url)).host
        else
          Capybara.app_host || "127.0.0.1"
        end
      end

      browser.set_cookie(options)
    end

    def remove_cookie(name)
      browser.remove_cookie(name)
    end

    def cookies_enabled=(flag)
      browser.cookies_enabled = flag
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
      [Capybara::Poltergeist::ObsoleteNode, Capybara::Poltergeist::MouseEventFailed]
    end
  end
end
