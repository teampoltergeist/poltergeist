require "timeout"
require "capybara/poltergeist/utility"

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

    attr_reader :pid, :server, :path, :window_size, :phantomjs_options

    def initialize(server, options = {})
      @server            = server
      @path              = options[:path]              || PHANTOMJS_NAME
      @window_size       = options[:window_size]       || [1024, 768]
      @phantomjs_options = options[:phantomjs_options] || []
      @phantomjs_logger  = options[:phantomjs_logger]  || $stdout

      pid = Process.pid
      at_exit { stop if Process.pid == pid }
    end

    def start
      check_phantomjs_version
      @read_io, @write_io = IO.pipe
      @out_thread = Thread.new {
        while !@read_io.eof? && data = @read_io.readpartial(1024)
          @phantomjs_logger.write(data)
        end
      }

      redirect_stdout do
        if Capybara::Poltergeist.windows?
          @pid = Process.spawn(*command.map(&:to_s))
        else
          @pid = Process.spawn(*command.map(&:to_s), pgroup: true)
        end
        ObjectSpace.define_finalizer(self, self.class.process_killer(@pid) )
      end
    end

    # Returns a proc, that when called will attempt to kill the given process.
    # This is because implementing ObjectSpace.define_finalizer is tricky.
    # Hat-Tip to @mperham for describing in detail:
    # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
    def self.process_killer(pid)
      proc do
        begin
          Proces.kill('KILL', pid)
        rescue Errno::ESRCH, Errno::ECHILD
        end
      end
    end

    def stop
      if pid
        begin
          if Capybara::Poltergeist.windows?
            Process.kill('KILL', pid)
          else
            Process.kill('TERM', pid)
            begin
              Timeout.timeout(KILL_TIMEOUT) { Process.wait(pid) }
            rescue Timeout::Error
              Process.kill('KILL', pid)
              Process.wait(pid)
            end
          end
        rescue Errno::ESRCH, Errno::ECHILD
          # Zed's dead, baby
        end
        ObjectSpace.undefine_finalizer(self)
        @write_io.close
        @read_io.close
        @out_thread.kill
        @pid = nil
      end
    end

    def restart
      stop
      start
    end

    def command
      parts = [path]
      parts.concat phantomjs_options
      parts << PHANTOMJS_SCRIPT
      parts << server.port
      parts.concat window_size
      parts
    end

    private

    def check_phantomjs_version
      return if @phantomjs_version_checked

      version = `#{path} --version` rescue nil

      if version.nil? || $? != 0
        raise PhantomJSFailed.new($?)
      else
        major, minor, build = version.chomp.split('.').map(&:to_i)
        min_major, min_minor, min_build = PHANTOMJS_VERSION.split('.').map(&:to_i)
        if major < min_major ||
            major == min_major && minor < min_minor ||
            major == min_major && minor == min_minor && build < min_build
          raise PhantomJSTooOld.new(version)
        end
      end

      @phantomjs_version_checked = true
    end

    # This abomination is because JRuby doesn't support the :out option of
    # Process.spawn
    def redirect_stdout
      prev = STDOUT.dup
      prev.autoclose = false
      $stdout = @write_io
      STDOUT.reopen(@write_io)
      yield
    ensure
      STDOUT.reopen(prev)
      $stdout = STDOUT
    end
  end
end
