# frozen_string_literal: true

class SpecLogger
  attr_reader :messages

  def reset
    @messages = []
  end

  def puts(message)
    @messages << message
  end
end
