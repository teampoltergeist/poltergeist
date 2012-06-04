require 'rspec/core/rake_task'

base = File.dirname(__FILE__)
require base + "/lib/capybara/poltergeist/version"
require 'coffee-script'

task :autocompile do
  system "coffee --compile --bare --watch " \
         "--output lib/capybara/poltergeist/client/compiled " \
         "lib/capybara/poltergeist/client/*.coffee"
end

task :compile do
  Dir.glob("lib/capybara/poltergeist/client/*.coffee").each do |f|
    compiled = "lib/capybara/poltergeist/client/compiled/#{f.split("/").last.split(".").first}.js"
    File.open(compiled, "w") do |out|
      out << CoffeeScript.compile(File.read(f), :bare => true)
    end
  end
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
