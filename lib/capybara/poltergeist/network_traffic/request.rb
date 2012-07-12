module Capybara::Poltergeist::NetworkTraffic
  class Request
    attr_reader :response_parts

    def initialize(data, response_parts = [])
      @data           = data
      @response_parts = response_parts
    end

    def url
      @data['url']
    end

    def method
      @data['method']
    end

    def headers
      @data['headers']
    end

    def time
      @data['time'] && Time.parse(@data['time'])
    end
  end
end
