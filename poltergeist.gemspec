lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'capybara/poltergeist/version'

Gem::Specification.new do |s|
  s.name          = 'poltergeist'
  s.version       = Capybara::Poltergeist::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Jon Leighton']
  s.email         = ['j@jonathanleighton.com']
  s.homepage      = 'https://github.com/teampoltergeist/poltergeist'
  s.summary       = 'PhantomJS driver for Capybara'
  s.description   = 'Poltergeist is a driver for Capybara that allows you to '\
                    'run your tests on a headless WebKit browser, provided by '\
                    'PhantomJS.'
  s.license       = 'MIT'
  s.require_paths = ['lib']
  s.files         = Dir.glob('{lib}/**/*') + %w(LICENSE README.md)

  s.required_ruby_version = '>= 1.9.3'

  s.add_runtime_dependency 'capybara',         '~> 2.1'
  s.add_runtime_dependency 'websocket-driver', '>= 0.2.0'
  s.add_runtime_dependency 'multi_json',       '~> 1.0'
  s.add_runtime_dependency 'cliver',           '~> 0.3.1'

  s.add_development_dependency 'launchy',            '~> 2.0'
  s.add_development_dependency 'rspec',              '~> 3.4.0'
  s.add_development_dependency 'rspec-core',         '!= 3.4.0' # 3.4.0 has an issue with rbx and ripper
  s.add_development_dependency 'sinatra',            '~> 1.0'
  s.add_development_dependency 'rake',               '~> 10.0'
  s.add_development_dependency 'image_size',         '~> 1.0'
  s.add_development_dependency 'pdf-reader',         '~> 1.3.3'
  s.add_development_dependency 'coffee-script',      '~> 2.2'
  s.add_development_dependency 'guard-coffeescript', '~> 2.0.0'
end
