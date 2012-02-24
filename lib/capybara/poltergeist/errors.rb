module Capybara
  module Poltergeist
    class Error < StandardError
    end

    class BrowserError < Error
      attr_reader :response

      def initialize(response)
        @response = response
      end

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

    class NodeError < Error
      attr_reader :node, :response

      def initialize(node, response)
        @node     = node
        @response = response
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
        "Click at co-ordinates #{position} failed. Poltergeist detected " \
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
  end
end
