require 'bundler/setup'
require 'rspec/core/rake_task'

require 'capybara/poltergeist/version'
require 'coffee-script'
require 'rspec-rerun'

task :autocompile do
  system "guard"
end

task :compile do
  Dir.glob("lib/capybara/poltergeist/client/*.coffee").each do |f|
    compiled = "lib/capybara/poltergeist/client/compiled/#{f.split("/").last.split(".").first}.js"
    File.open(compiled, "w") do |out|
      puts "Compiling #{f}"
      out << CoffeeScript.compile(File.read(f), :bare => true)
    end
  end
end

RSpec::Core::RakeTask.new('test')

task :default => [:compile, :test]
task :ci => 'rspec-rerun:spec'

task :release do
  puts "Releasing #{Capybara::Poltergeist::VERSION}, y/n?"
  exit(1) unless STDIN.gets.chomp == "y"
  sh "gem build poltergeist.gemspec && " \
     "gem push poltergeist-#{Capybara::Poltergeist::VERSION}.gem && " \
     "git tag v#{Capybara::Poltergeist::VERSION} && " \
     "git push --tags"
end
