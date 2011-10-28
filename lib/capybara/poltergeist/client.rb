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
      @err = IO.pipe
      @pid = Kernel.spawn("#{path} #{PHANTOM_SCRIPT} #{port}", :err => err.last)

      @thread = Thread.new do
        loop do
          line = err.first.readline

          # QtWebkit seems to throw this error all the time when using WebSockets, but
          # it doesn't appear to actually stop anything working, so filter it out.
          #
          # This isn't the nicest solution I know :( Hopefully it will be fixed in
          # QtWebkit (if you search for this string, you'll see it's been reported in
          # various places).
          unless line.include?('WebCore::SocketStreamHandlePrivate::socketSentData()')
            STDERR.puts line
          end
        end
      end
    end

    def stop
      thread.kill
      Process.kill('TERM', pid)
      err.each { |io| io.close unless io.closed? }
    end

    def restart
      stop
      start
    end
  end
end
