module Capybara::Poltergeist
  class Driver < Capybara::Driver::Base
    attr_reader :app, :server, :browser, :options

    def initialize(app, options = {})
      @app     = app
      @options = options
      @server  = Capybara::Server.new(app)
      @browser = nil

      @server.boot if Capybara.run_server
    end

    def browser
      @browser ||= Browser.new(
        :logger    => logger,
        :phantomjs => options[:phantomjs]
      )
    end

    def restart
      browser.restart
    end

    # logger should be an object that responds to puts, or nil
    def logger
      options[:logger] || (options[:debug] && STDERR)
    end

    def visit(path, attributes = {})
      browser.visit(url(path), attributes)
    end

    def current_url
      browser.current_url
    end

    def body
      browser.body
    end

    def source
      browser.source
    end

    def find(selector)
      browser.find(selector).map { |node| Capybara::Poltergeist::Node.new(self, node) }
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

    def render(path)
      browser.render(path)
    end

    def wait?
      true
    end

    def invalid_element_errors
      [Capybara::Poltergeist::ObsoleteNode]
    end

    private

    def url(path)
      server.url(path)
    end
  end
end
