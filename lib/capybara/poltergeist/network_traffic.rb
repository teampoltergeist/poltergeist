module Capybara
  module Poltergeist

    # holds information about a single request the browser performed
    class NetworkTraffic

      Request  = Struct.new(:url,
                            :method,
                            :headers,
                            :time)

      Response = Struct.new(:status,
                            :status_text,
                            :headers,
                            :redirect_url,
                            :body_size,
                            :time)

      attr_reader :request, :response

      def initialize request_info
        @request  = construct_from_hash Request, request_info['request']
        @response = construct_from_hash Response, request_info['endReply']
        if request_info['startReply']
          @response.body_size = request_info['startReply']['bodySize']
        end
        @request.time  = Time.parse(@request.time)  if @request.time
        @response.time = Time.parse(@response.time) if @response.time
      end

      def url
        request.url
      end

      private

      def construct_from_hash struct, hash
        object = struct.new
        if hash
          hash.each_pair do |key, value|
            setter = "#{underscorize(key)}="
            object.send(setter, value) if object.respond_to? setter
          end
        end
        object
      end

      def underscorize string
        string.gsub(/(.)([A-Z])/, '\1_\2').downcase
      end

    end

  end
end
