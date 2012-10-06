module Capybara::Poltergeist
  class Cookie
    def initialize(attributes)
      @attributes = attributes
    end

    def name
      @attributes['name']
    end

    def value
      @attributes['value']
    end

    def domain
      @attributes['domain']
    end

    def path
      @attributes['path']
    end

    def secure?
      @attributes['secure']
    end

    def httponly?
      @attributes['httponly']
    end

    def expires
      Time.parse @attributes['expires']
    end
  end
end
