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
      if @options[:window_size]
        @width, @height = @options[:window_size]
      end

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
      @server ||= Server.new(options.fetch(:timeout, DEFAULT_TIMEOUT))
    end

    def client
      @client ||= Client.start(server.port, inspector, options[:phantomjs], @width, @height)
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

    def within_frame(id, &block)
      browser.within_frame(id, &block)
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

    def debug
      inspector.open
      pause
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
