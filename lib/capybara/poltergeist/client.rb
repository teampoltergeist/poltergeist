require 'open3'

module Capybara::Poltergeist
  class Client
    PHANTOM_SCRIPT = File.expand_path('../client/compiled/main.js', __FILE__)

    attr_reader :pid, :port, :path

    def initialize(port, path = nil)
      @port = port
      @path = path || 'phantomjs'

      start
      at_exit { stop }
    end

    def start
      @pid = Process.fork do
        Open3.popen3("#{path} #{PHANTOM_SCRIPT} #{port}") do |stdin, stdout, stderr|
          loop do
            select = IO.select([stdout, stderr])
            stream = select.first.first

            break if stream.eof?

            if stream == stdout
              STDOUT.puts stdout.readline
            elsif stream == stderr
              line = stderr.readline

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
      end
    end

    def stop
      Process.kill('TERM', pid)
    rescue Errno::ESRCH
      # Bovvered, I ain't
    end

    def restart
      stop
      start
    end
  end
end
