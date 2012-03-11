require 'childprocess'

module Capybara::Poltergeist
  module Spawn
    def self.spawn(*args)
      args = args.map(&:to_s)

      if RUBY_VERSION >= "1.9"
        Process.spawn(*args)
      else
        process = ChildProcess.build(*args)
        process.start
        process.pid
      end
    end
  end
end
