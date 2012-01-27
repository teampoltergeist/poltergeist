module Capybara
  module Poltergeist
    class Error < StandardError
    end

    class BrowserError < Error
      attr_reader :text

      def initialize(text)
        @text = text
      end

      def message
        "Received error from PhantomJS client: #{text}"
      end
    end

    class ObsoleteNode < Error
      attr_reader :node

      def initialize(node)
        @node = node
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
