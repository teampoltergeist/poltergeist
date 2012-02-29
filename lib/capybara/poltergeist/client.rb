require 'sfl'

module Capybara::Poltergeist
  class Client
    PHANTOMJS_SCRIPT  = File.expand_path('../client/compiled/main.js', __FILE__)
    PHANTOMJS_VERSION = '1.4.1'
    PHANTOMJS_NAME    = 'phantomjs'

    def self.start(*args)
      client = new(*args)
      client.start
      client
    end

    attr_reader :pid, :port, :path, :inspector

    def initialize(port, inspector = nil, path = nil)
      @port      = port
      @inspector = inspector
      @path      = path || PHANTOMJS_NAME
      at_exit { stop }
    end

    def start
      check_phantomjs_version
      @pid = Kernel.spawn(command)
    end

    def stop
      if pid
        begin
          Process.kill('TERM', pid)
          Process.wait(pid)
        rescue Errno::ESRCH, Errno::ECHILD
          # Zed's dead, baby
        end

        @pid = nil
      end
    end

    def restart
      stop
      start
    end

    def command
      @command ||= begin
        parts = [path]

        if inspector
          parts << "--remote-debugger-port=#{inspector.port}"
          parts << "--remote-debugger-autorun=yes"
        end

        parts << PHANTOMJS_SCRIPT
        parts << port
        parts.join(" ")
      end
    end

    private

    def check_phantomjs_version
      return if @phantomjs_version_checked

      version = `#{path} --version`.chomp

      if $? != 0
        raise PhantomJSFailed.new($?)
      elsif version < PHANTOMJS_VERSION
        raise PhantomJSTooOld.new(version)
      end

      @phantomjs_version_checked = true
    end
  end
end
