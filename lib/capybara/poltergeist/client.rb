module Capybara::Poltergeist
  class Client
    PHANTOMJS_SCRIPT  = File.expand_path('../client/compiled/main.js', __FILE__)
    PHANTOMJS_VERSION = '1.8.1'
    PHANTOMJS_NAME    = 'phantomjs'

    KILL_TIMEOUT = 2 # seconds

    def self.start(*args)
      client = new(*args)
      client.start
      client
    end

    attr_reader :pid, :port, :path, :window_size, :phantomjs_options

    def initialize(port, options = {})
      @port              = port
      @path              = options[:path]              || PHANTOMJS_NAME
      @window_size       = options[:window_size]       || [1024, 768]
      @phantomjs_options = options[:phantomjs_options] || []

      pid = Process.pid
      at_exit { stop if Process.pid == pid }
    end

    def start
      check_phantomjs_version
      @pid = Process.spawn(*command.map(&:to_s))
    end

    def stop
      if pid
        begin
          Process.kill('TERM', pid)

          timeout = Time.now + KILL_TIMEOUT
          status  = nil

          while status.nil? && Time.now < timeout
            status = Process.wait(pid, Process::WNOHANG)
            sleep 0.1 unless status
          end

          unless status
            Process.kill('KILL', pid)
            Process.wait(pid)
          end
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
        parts.concat phantomjs_options
        parts << PHANTOMJS_SCRIPT
        parts << port
        parts.concat window_size
        parts
      end
    end

    private

    def check_phantomjs_version
      return if @phantomjs_version_checked

      version = `#{path} --version` rescue nil

      if version.nil? || $? != 0
        raise PhantomJSFailed.new($?)
      elsif version.chomp < PHANTOMJS_VERSION
        raise PhantomJSTooOld.new(version)
      end

      @phantomjs_version_checked = true
    end
  end
end
