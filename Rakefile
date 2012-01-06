require 'rspec/core/rake_task'

base = File.dirname(__FILE__)
require base + "/lib/capybara/poltergeist/version"

task :autocompile do
  system "coffee --compile --bare --watch " \
         "--output lib/capybara/poltergeist/client/compiled " \
         "lib/capybara/poltergeist/client/*.coffee"
end

RSpec::Core::RakeTask.new('test') do
end

task :default => :test

task :release do
  puts "Releasing #{Capybara::Poltergeist::VERSION}, y/n?"
  exit(1) unless STDIN.gets.chomp == "y"
  sh "gem build poltergeist.gemspec && " \
     "gem push poltergeist-#{Capybara::Poltergeist::VERSION}.gem && " \
     "git tag v#{Capybara::Poltergeist::VERSION} && " \
     "git push --tags"
end
