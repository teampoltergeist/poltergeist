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

    class JSErrorItem
      attr_reader :message, :stack

      def initialize(message, stack)
        @message = message
        @stack   = stack
      end

      def to_s
        stack
      end
    end

    class BrowserError < ClientError
      def name
        response['name']
      end

      def javascript_error
        JSErrorItem.new(*response['args'])
      end

      def message
        "There was an error inside the PhantomJS portion of Poltergeist:\n\n#{javascript_error}"
      end
    end

    class JavascriptError < ClientError
      def javascript_errors
        response['args'].first.map { |data| JSErrorItem.new(data['message'], data['stack']) }
      end

      def message
        "One or more errors were raised in the Javascript code on the page:\n\n" +
          javascript_errors.map(&:to_s).join("\n")
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

    class TouchFailed < NodeError
      def selector
        response['args'][0]
      end

      def position
        [response['args'][1]['x'], response['args'][1]['y']]
      end

      def message
        "Touch at co-ordinates [#{position.join(', ')}] failed. Poltergeist detected " \
          "another element with CSS selector '#{selector}' at this position. " \
          "It may be overlapping the element you are trying to tap."
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
        "PhantomJS returned non-zero exit status #{status.exitstatus}. Make sure phantomjs runs successfully " \
          "on your system. You can test this by just running the `phantomjs` command which should give you " \
          "a Javascript REPL."
      end
    end
  end
end
