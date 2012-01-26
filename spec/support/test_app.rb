require 'capybara/spec/test_app'

class TestApp
  POLTERGEIST_VIEWS  = File.dirname(__FILE__) + "/views"
  POLTERGEIST_PUBLIC = File.dirname(__FILE__) + "/public"

  get '/poltergeist/test.js' do
    File.read("#{POLTERGEIST_PUBLIC}/test.js")
  end

  get '/poltergeist/:view' do |view|
    erb File.read("#{POLTERGEIST_VIEWS}/#{view}.erb")
  end

  post '/poltergeist' do
    params[:name]
  end
end
