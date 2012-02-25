require 'sfl'

module Capybara::Poltergeist
  class Client
    INSPECTOR_BROWSERS = %w(chromium chromium-browser google-chrome safari)
    PHANTOMJS_SCRIPT   = File.expand_path('../client/compiled/main.js', __FILE__)
    PHANTOMJS_VERSION  = '1.4.1'
    PHANTOMJS_NAME     = 'phantomjs'

    def self.inspector_browser
      @inspector_browser ||= INSPECTOR_BROWSERS.find do |name|
        system "which #{name} &>/dev/null"
      end
    end

    def self.start(*args)
      client = new(*args)
      client.start
      client
    end

    attr_reader :pid, :port, :path, :inspector

    def initialize(port, inspector = false, path = nil)
      @port      = port
      @inspector = inspector
      @path      = path || PHANTOMJS_NAME
      at_exit { stop }
    end

    def start
      check_phantomjs_version
      @pid = Kernel.spawn(command)

      # Opens a remote debugger for the phantomjs session. This feature
      # is unfinished / experimental. When the debugger opens, you have
      # to type __run() into the console to get it going.
      Kernel.spawn(inspector_command) if inspector
    end

    def stop
      Process.kill('TERM', pid) if pid
    end

    def restart
      stop
      start
    end

    def command
      @command ||= begin
        parts = [path]
        parts << "--remote-debugger-port=#{inspector_port}" if inspector
        parts << PHANTOMJS_SCRIPT
        parts << port
        parts.join(" ")
      end
    end

    def inspector_port
      @inspector_port ||= Util.find_available_port
    end

    def inspector_command
      "#{inspector_browser} http://localhost:#{inspector_port}/webkit/inspector/inspector.html?page=1"
    end

    def inspector_browser
      if inspector == true
        self.class.inspector_browser or raise "webkit browser not found; please specify it explicitly"
      else
        inspector
      end
    end

    private

    def check_phantomjs_version
      return if @phantomjs_version_checked

      version = `#{path} --version`.chomp
      if version < PHANTOMJS_VERSION
        raise PhantomJSTooOld.new(version)
      end
      @phantomjs_version_checked = true
    end
  end
end
