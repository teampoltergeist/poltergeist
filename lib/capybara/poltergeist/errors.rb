module Capybara
  module Poltergeist
    class Error < StandardError
    end

    class ClientError < Error
      attr_reader :response

      def initialize(response)
        @response = response
      end
    end

    class BrowserError < ClientError
      def name
        response['name']
      end

      def text
        response['args'].first
      end

      def message
        "Received error from PhantomJS client: #{text}"
      end
    end

    class JavascriptError < ClientError
      def javascript_messages
        response['args'].first
      end

      def message
        "One or more errors were raised in the Javascript code on the page: #{javascript_messages.inspect} " \
          "Unfortunately, it is not currently possible to provide a stack trace, or even the line/file where " \
          "the error occurred. (This is due to lack of support within QtWebKit.) Fixing this is a high " \
          "priority, but we're not there yet."
      end
    end

    class NodeError < ClientError
      attr_reader :node

      def initialize(node, response)
        @node = node
        super(response)
      end
    end

    class ObsoleteNode < NodeError
    end

    class ClickFailed < NodeError
      def selector
        response['args'][0]
      end

      def position
        [response['args'][1]['x'], response['args'][1]['y']]
      end

      def message
        "Click at co-ordinates [#{position.join(', ')}] failed. Poltergeist detected " \
          "another element with CSS selector '#{selector}' at this position. " \
          "It may be overlapping the element you are trying to click."
      end
    end

    class TimeoutError < Error
      def initialize(message)
        @message = message
      end

      def message
        "Timed out waiting for response to #{@message}"
      end
    end

    class DeadClient < Error
      def initialize(message)
        @message = message
      end

      def message
        "The PhantomJS client died while processing #{@message}"
      end
    end

    class PhantomJSTooOld < Error
      attr_reader :version

      def initialize(version)
        @version = version
      end

      def message
        "PhantomJS version #{version} is too old. You must use at least version #{Client::PHANTOMJS_VERSION}"
      end
    end

    class PhantomJSFailed < Error
      attr_reader :status

      def initialize(status)
        @status = status
      end

      def message
        "PhantomJS returned non-zero exit status #{status.exitstatus}. Ensure there is an X display available and " \
          "that DISPLAY is set. (See the Poltergeist README for details.) Make sure 'phantomjs --version' " \
          "runs successfully on your system."
      end
    end
  end
end
