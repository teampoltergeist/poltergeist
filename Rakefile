require 'bundler/setup'
require 'rspec/core/rake_task'

require 'capybara/poltergeist/version'
require 'coffee-script'

RSpec::Core::RakeTask.new('test')
task default: [:compile, :test]

task(:autocompile) { system 'guard' }

task :compile do
  path = 'lib/capybara/poltergeist/client'
  Dir["#{path}/*.coffee"].each do |f|
    compiled = "#{path}/compiled/#{File.basename(f, '.coffee')}.js"
    File.open(compiled, 'w') do |out|
      puts "Compiling #{f}"
      out << CoffeeScript.compile(File.read(f), bare: true)
    end
  end
end

task :release do
  version = Capybara::Poltergeist::VERSION
  puts "Releasing #{version}, y/n?"
  exit(1) unless STDIN.gets.chomp == 'y'
  sh 'gem build poltergeist.gemspec && ' \
     "gem push poltergeist-#{version}.gem && " \
     "git tag v#{version} && " \
     'git push --tags'
end
