require 'capybara/spec/test_app'

class TestApp
  POLTERGEIST_VIEWS  = File.dirname(__FILE__) + "/views"
  POLTERGEIST_PUBLIC = File.dirname(__FILE__) + "/public"

  get '/poltergeist/test.js' do
    File.read("#{POLTERGEIST_PUBLIC}/test.js")
  end

  get '/poltergeist/jquery-1.6.2.min.js' do
    File.read("#{POLTERGEIST_PUBLIC}/jquery-1.6.2.min.js")
  end

  get '/poltergeist/jquery-ui-1.8.14.min.js' do
    File.read("#{POLTERGEIST_PUBLIC}/jquery-ui-1.8.14.min.js")
  end

  get '/poltergeist/unexist.png' do
    halt 404
  end

  get '/poltergeist/500' do
    halt 500
  end

  get '/poltergeist/redirect' do
    redirect '/poltergeist/with_different_resources'
  end

  get '/poltergeist/:view' do |view|
    erb File.read("#{POLTERGEIST_VIEWS}/#{view}.erb")
  end
end
