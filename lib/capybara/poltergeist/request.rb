module Capybara::Poltergeist

  class Request

    attr_reader :response_parts

    def initialize(data)
      @data = data
      @response_parts = []
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
