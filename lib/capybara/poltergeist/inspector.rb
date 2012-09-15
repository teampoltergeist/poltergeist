module Capybara::Poltergeist
  class Inspector
    BROWSERS = %w(chromium chromium-browser google-chrome open)

    def self.detect_browser
      @browser ||= BROWSERS.find { |name| browser_binary_exists?(name) }
    end

    def initialize(browser = nil)
      @browser = browser.respond_to?(:to_str) ? browser : nil
    end

    def browser
      @browser ||= self.class.detect_browser
    end

    def port
      @port ||= Util.find_available_port
    end

    def url
      "http://localhost:#{port}/"
    end

    def open
      if browser
        Spawn.spawn(browser, url)
      else
        raise Error, "Could not find a browser executable to open #{url}. " \
                     "You can specify one manually using e.g. `:inspector => 'chromium'` " \
                     "as a configuration option for Poltergeist."
      end
    end

    def self.browser_binary_exists?(browser)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
          exe = "#{path}#{File::SEPARATOR}#{browser}#{ext}"
          return exe if File.executable? exe
        }
      end
      return nil
    end
  end
end
