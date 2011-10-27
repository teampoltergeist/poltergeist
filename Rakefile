task :autocompile do
  system "coffee --compile --bare --watch " \
         "--output lib/capybara/poltergeist/client/compiled " \
         "lib/capybara/poltergeist/client/*.coffee"
end

task :test do
  system "rspec spec/"
end

task :default => :test
