require 'sfl'

module Capybara::Poltergeist
  class Client
    PHANTOMJS_SCRIPT  = File.expand_path('../client/compiled/main.js', __FILE__)
    PHANTOMJS_VERSION = "1.4.1"

    attr_reader :pid, :port, :path

    def self.start(*args)
      client = new(*args)
      client.start
      client
    end

    def initialize(port, path = nil)
      @port = port
      @path = path || 'phantomjs'
      at_exit { stop }
    end

    def start
      check_phantomjs_version
      @pid = Kernel.spawn("#{path} #{PHANTOMJS_SCRIPT} #{port}")
    end

    def stop
      Process.kill('TERM', pid) if pid
    end

    def restart
      stop
      start
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
