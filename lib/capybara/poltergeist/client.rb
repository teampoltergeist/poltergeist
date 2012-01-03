require 'sfl'

module Capybara::Poltergeist
  class Client
    PHANTOM_SCRIPT = File.expand_path('../client/compiled/main.js', __FILE__)

    attr_reader :thread, :pid, :err, :port, :path

    def initialize(port, path = nil)
      @port = port
      @path = path || 'phantomjs'

      start
      at_exit { stop }
    end

    def start
      @pid = Kernel.spawn("#{path} #{PHANTOM_SCRIPT} #{port}")
    end

    def stop
      Process.kill('TERM', pid)
    end

    def restart
      stop
      start
    end
  end
end
