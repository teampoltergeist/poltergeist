module Capybara::Poltergeist
  class Node < Capybara::Driver::Node
    attr_reader :page_id, :id

    def initialize(driver, page_id, id)
      super(driver, self)

      @page_id = page_id
      @id      = id
    end

    def browser
      driver.browser
    end

    def command(name, *args)
      browser.send(name, page_id, id, *args)
    rescue BrowserError => error
      case error.name
      when 'Poltergeist.ObsoleteNode'
        raise ObsoleteNode.new(self, error.response)
      when 'Poltergeist.ClickFailed'
        raise ClickFailed.new(self, error.response)
      when 'Poltergeist.TouchFailed'
        raise TouchFailed.new(self, error.response)
      else
        raise
      end
    end

    def find(selector)
      command(:find_within, selector).map { |id| self.class.new(driver, page_id, id) }
    end

    def text
      command(:text).strip.gsub(/\s+/, ' ')
    end

    def [](name)
      command :attribute, name
    end

    def value
      command :value
    end

    def set(value)
      if tag_name == 'input'
        case self[:type]
        when 'radio'
          click
        when 'checkbox'
          click if value != checked?
        when 'file'
          command :select_file, value
        else
          command :set, value.to_s
        end
      elsif tag_name == 'textarea'
        command :set, value.to_s
      end
    end

    def select_option
      command :select, true
    end

    def unselect_option
      command(:select, false) or
      raise(Capybara::UnselectNotAllowed, "Cannot unselect option from single select box.")
    end

    def tag_name
      @tag_name ||= command(:tag_name)
    end

    def visible?
      command :visible?
    end

    def checked?
      self[:checked]
    end

    def selected?
      self[:selected]
    end

    def click
      command :click
    end

    def single_tap
      command :single_tap
    end

    def drag_to(other)
      command :drag, other.id
    end

    def trigger(event)
      command :trigger, event
    end

    def ==(other)
      command :equals, other.id
    end
  end
end
