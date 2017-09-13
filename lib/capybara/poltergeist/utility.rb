# frozen_string_literal: true

module Capybara
  module Poltergeist
    class << self
      def windows?
        RbConfig::CONFIG["host_os"] =~ /mingw|mswin|cygwin/
      end

      def mri?
        defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby"
      end
    end
  end
end
