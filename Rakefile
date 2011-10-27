require 'rspec/core/rake_task'

task :autocompile do
  system "coffee --compile --bare --watch " \
         "--output lib/capybara/poltergeist/client/compiled " \
         "lib/capybara/poltergeist/client/*.coffee"
end

RSpec::Core::RakeTask.new('test') do
end

task :default => :test
