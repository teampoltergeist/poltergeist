module Capybara::Poltergeist
  class Node < Capybara::Driver::Node
    alias id native

    def browser
      driver.browser
    end

    def command(name, *args)
      browser.send(name, id, *args)
    rescue BrowserError => error
      if error.text == 'Poltergeist.ObsoleteNode'
        raise ObsoleteNode.new(self)
      else
        raise error
      end
    end

    def find(selector)
      browser.find(selector, id).map { |node| self.class.new(driver, node) }
    end

    def text
      command :text
    end

    def [](name)
      command :attribute, name
    end

    def value
      command :value
    end

    def set(value)
      if tag_name == 'input'
        type = self[:type]

        if type == 'radio'
          click
        elsif type == 'checkbox'
          if value && !checked? || !value && checked?
            click
          end
        elsif type == 'file'
          command :select_file, value
        else
          command :set, value
        end
      elsif tag_name == 'textarea'
        command :set, value
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

    def drag_to(other)
      command :drag, other.id
    end

    def trigger(event)
      command :trigger, event
    end
  end
end
