require "timeout"
require "capybara/poltergeist/utility"
require 'cliver'

module Capybara::Poltergeist
  class Client
    PHANTOMJS_SCRIPT  = File.expand_path('../client/compiled/main.js', __FILE__)
    PHANTOMJS_VERSION = ['~> 1.8','>= 1.8.1']
    PHANTOMJS_NAME    = 'phantomjs'

    KILL_TIMEOUT = 2 # seconds

    def self.start(*args)
      client = new(*args)
      client.start
      client
    end

    # Returns a proc, that when called will attempt to kill the given process.
    # This is because implementing ObjectSpace.define_finalizer is tricky.
    # Hat-Tip to @mperham for describing in detail:
    # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
    def self.process_killer(pid)
      proc do
        begin
          Process.kill('KILL', pid)
        rescue Errno::ESRCH, Errno::ECHILD
        end
      end
    end

    attr_reader :pid, :server, :path, :window_size, :phantomjs_options

    def initialize(server, options = {})
      @server            = server
      @path              = Cliver::detect!((options[:path] || PHANTOMJS_NAME),
                                           *PHANTOMJS_VERSION)

      @window_size       = options[:window_size]       || [1024, 768]
      @phantomjs_options = options[:phantomjs_options] || []
      @phantomjs_logger  = options[:phantomjs_logger]  || $stdout

      pid = Process.pid
      at_exit { stop if Process.pid == pid }
    end

    def start
      @read_io, @write_io = IO.pipe
      @out_thread = Thread.new {
        while !@read_io.eof? && data = @read_io.readpartial(1024)
          @phantomjs_logger.write(data)
        end
      }

      process_options = {}
      process_options[:pgroup] = true unless Capybara::Poltergeist.windows?

      redirect_stdout do
        @pid = Process.spawn(*command.map(&:to_s), process_options)
        ObjectSpace.define_finalizer(self, self.class.process_killer(@pid) )
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
