require 'capybara/spec/test_app'

class TestApp
  configure do
    set :protection, :except => :frame_options
  end
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

  get '/poltergeist/status/:status' do
    status params['status']
    render_view 'with_different_resources'
  end

  get '/poltergeist/redirect' do
    redirect '/poltergeist/with_different_resources'
  end

  get '/poltergeist/get_cookie' do
    request.cookies['capybara']
  end

  get '/poltergeist/slow' do
    sleep 0.2
    "slow page"
  end

  get '/poltergeist/:view' do |view|
    render_view view
  end

  get '/poltergeist/arbitrary_path/:status/:remaining_path' do
    status params['status'].to_i
    params['remaining_path']
  end

  protected

  def render_view(view)
    erb File.read("#{POLTERGEIST_VIEWS}/#{view}.erb")
  end
end
