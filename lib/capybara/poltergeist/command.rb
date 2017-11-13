# frozen_string_literal: true

require 'securerandom'

module Capybara::Poltergeist
  class Command
    attr_reader :id
    attr_reader :name
    attr_accessor :args

    def initialize(name, *args)
      @id = SecureRandom.uuid
      @name = name
      @args = args
    end

    def message
      JSON.dump({ 'id' => @id, 'name' => @name, 'args' => @args })
    end
  end
end
