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
  end
end
