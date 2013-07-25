require 'spec_helper'
require 'image_size'

module Capybara::Poltergeist
  describe Driver do
    before do
      @session = TestSessions::Poltergeist
      @driver = @session.driver
    end

    after do
      @driver.reset!
    end

    def session_url(path)
      server = @session.server
      "http://#{server.host}:#{server.port}#{path}"
    end

    it 'supports a custom phantomjs path' do
      begin
        file = POLTERGEIST_ROOT + '/spec/support/custom_phantomjs_called'
        path = POLTERGEIST_ROOT + '/spec/support/custom_phantomjs'

        FileUtils.rm_f file

        driver  = Capybara::Poltergeist::Driver.new(nil, :phantomjs => path)
        driver.browser

        # If the correct custom path is called, it will touch the file. We allow at
        # least 10 secs for this to happen before failing.

        tries = 0
        until File.exist?(file) || tries == 100
          sleep 0.1
          tries += 1
        end

        File.exist?(file).should == true
      ensure
        driver.quit if driver
      end
    end

    it 'supports capturing console.log' do
      output = StringIO.new
      Capybara.register_driver :poltergeist_with_logger do |app|
        Capybara::Poltergeist::Driver.new(app, :phantomjs_logger => output)
      end

      session = Capybara::Session.new(:poltergeist_with_logger, TestApp)
      session.visit('/poltergeist/console_log')
      output.string.should include('Hello world')
    end

    it 'raises an error and restarts the client, if the client dies while executing a command' do
      lambda { @driver.browser.command('exit') }.should raise_error(DeadClient)
      @session.visit('/')
      @driver.html.should include('Hello world')
    end

    it 'has a viewport size of 1024x768 by default' do
      @session.visit('/')
      @driver.evaluate_script('[window.innerWidth, window.innerHeight]').should == [1024, 768]
    end

    it 'allows the viewport to be resized' do
      begin
        @session.visit('/')
        @driver.resize(200, 400)
        @driver.evaluate_script('[window.innerWidth, window.innerHeight]').should == [200, 400]
      ensure
        @driver.resize(1024, 768)
      end
    end

    it 'supports specifying viewport size with an option' do
      begin
        Capybara.register_driver :poltergeist_with_custom_window_size do |app|
          Capybara::Poltergeist::Driver.new(
            app,
            :logger      => TestSessions.logger,
            :window_size => [800, 600]
          )
        end
        driver = Capybara::Session.new(:poltergeist_with_custom_window_size, TestApp).driver
        driver.visit(session_url '/')
        driver.evaluate_script('[window.innerWidth, window.innerHeight]').should eq([800, 600])
      ensure
        driver.quit if driver
      end
    end

    it 'supports rendering the page' do
      file = POLTERGEIST_ROOT + '/spec/tmp/screenshot.png'
      FileUtils.rm_f file
      @session.visit('/')
      @driver.save_screenshot(file)
      File.exist?(file).should == true
    end

    it 'supports rendering the whole of a page that goes outside the viewport' do
      file = POLTERGEIST_ROOT + '/spec/tmp/screenshot.png'
      @session.visit('/poltergeist/long_page')
      @driver.save_screenshot(file)

      File.open(file, 'rb') do |f|
        ImageSize.new(f.read).size.should ==
          @driver.evaluate_script('[window.innerWidth, window.innerHeight]')
      end

      @driver.save_screenshot(file, :full => true)

      File.open(file, 'rb') do |f|
        ImageSize.new(f.read).size.should ==
          @driver.evaluate_script('[document.documentElement.clientWidth, document.documentElement.clientHeight]')
      end
    end

    context 'setting headers' do
      it 'allows headers to be set' do
        @driver.headers = {
          "Cookie" => "foo=bar",
          "Host" => "foo.com"
        }
        @session.visit('/poltergeist/headers')
        @driver.body.should include('COOKIE: foo=bar')
        @driver.body.should include('HOST: foo.com')
      end

      it 'allows headers to be read' do
        expect(@driver.headers).to eq({})
        @driver.headers = { 'User-Agent' => 'PhantomJS', 'Host' => 'foo.com' }
        expect(@driver.headers).to eq('User-Agent' => 'PhantomJS', 'Host' => 'foo.com')
      end

      it 'supports User-Agent' do
        @driver.headers = { 'User-Agent' => 'foo' }
        @session.visit '/'
        @driver.evaluate_script('window.navigator.userAgent').should == 'foo'
      end

      it 'sets headers for all HTTP requests' do
        @driver.headers = { 'X-Omg' => 'wat' }
        @session.visit '/'
        @driver.execute_script <<-JS
          var request = new XMLHttpRequest();
          request.open('GET', '/poltergeist/headers', false);
          request.send();

          if (request.status === 200) {
            document.body.innerHTML = request.responseText;
          }
        JS
        @driver.body.should include('X_OMG: wat')
      end

      it 'adds new headers' do
        @driver.headers = { 'User-Agent' => 'PhantomJS', 'Host' => 'foo.com' }
        @driver.add_headers('User-Agent' => 'Poltergeist', 'Appended' => 'true')
        @session.visit('/poltergeist/headers')
        expect(@driver.body).to include('USER_AGENT: Poltergeist')
        expect(@driver.body).to include('HOST: foo.com')
        expect(@driver.body).to include('APPENDED: true')
      end

      it 'sets headers on the initial request' do
        @driver.headers = { 'PermanentA' => 'a' }
        @driver.add_headers('PermanentB' => 'b')
        @driver.add_header('Referer', 'http://google.com', :permanent => false)
        @driver.add_header('TempA', 'a', :permanent => false)

        @session.visit('/poltergeist/headers_with_ajax')
        initial_request = @session.find(:css, '#initial_request').text
        ajax_request = @session.find(:css, '#ajax_request').text

        expect(initial_request).to include('PERMANENTA: a')
        expect(initial_request).to include('PERMANENTB: b')
        expect(initial_request).to include('REFERER: http://google.com')
        expect(initial_request).to include('TEMPA: a')

        expect(ajax_request).to include('PERMANENTA: a')
        expect(ajax_request).to include('PERMANENTB: b')
        expect(ajax_request).not_to include('REFERER: http://google.com')
        expect(ajax_request).not_to include('TEMPA: a')
      end
    end

    it 'supports rendering the page with a nonstring path' do
      file = POLTERGEIST_ROOT + '/spec/tmp/screenshot.png'
      FileUtils.rm_f file
      @session.visit('/')
      @driver.save_screenshot(Pathname(file))
      File.exist?(file).should == true
    end

    it 'supports clicking precise coordinates' do
      @session.visit('/poltergeist/click_coordinates')
      @driver.click(100, 150)
      @driver.body.should include('x: 100, y: 150')
    end

    it 'supports executing multiple lines of javascript' do
      @driver.execute_script <<-JS
        var a = 1
        var b = 2
        window.result = a + b
      JS
      @driver.evaluate_script("result").should == 3
    end

    it 'operates a timeout when communicating with phantomjs' do
      begin
        prev_timeout = @driver.timeout
        @driver.timeout = 0.001
        lambda { @driver.browser.command 'noop' }.should raise_error(TimeoutError)
      ensure
        @driver.timeout = prev_timeout
      end
    end

    unless Capybara::Poltergeist.windows?
      # Not sure how to do this on Windows, so skipping
      it 'supports quitting the session' do
        driver = Capybara::Poltergeist::Driver.new(nil)
        pid    = driver.client_pid

        Process.kill(0, pid).should == 1
        driver.quit

        begin
          Process.kill(0, pid)
        rescue Errno::ESRCH
        else
          raise "process is still alive"
        end
      end
    end

    context 'extending browser javascript' do
      before do
        @extended_driver = Capybara::Poltergeist::Driver.new(
          @session.app,
          :logger     => TestSessions.logger,
          :inspector  => (ENV['DEBUG'] != nil),
          :extensions => %W% #{File.expand_path '../../support/geolocation.js', __FILE__ } %
        )
      end

      it 'supports extending the phantomjs world' do
        @extended_driver.visit session_url("/poltergeist/requiring_custom_extension")
        @extended_driver.body.should include(%Q%Location: <span id="location">1,-1</span>%)
        @extended_driver.evaluate_script("document.getElementById('location').innerHTML").should == '1,-1'
        @extended_driver.evaluate_script('navigator.geolocation').should_not eq nil
      end
    end

    context 'javascript errors' do
      it 'propagates a Javascript error inside Poltergeist to a ruby exception' do
        expect { @driver.browser.command 'browser_error' }.to raise_error(BrowserError)

        begin
          @driver.browser.command 'browser_error'
        rescue BrowserError => e
          e.message.should include("Error: zomg")
          e.message.should include("compiled/browser.js")
        else
          raise "BrowserError expected"
        end
      end

      it 'propagates an asynchronous Javascript error on the page to a ruby exception' do
        @driver.execute_script "setTimeout(function() { omg }, 0)"
        sleep 0.01
        expect { @driver.execute_script "" }.to raise_error(JavascriptError)

        begin
          @driver.execute_script "setTimeout(function() { omg }, 0)"
          sleep 0.01
          @driver.execute_script ""
        rescue JavascriptError => e
          e.message.should include("omg")
          e.message.should include("ReferenceError")
        else
          raise "expected JavascriptError"
        end
      end

      it 'propagates a synchronous Javascript error on the page to a ruby exception' do
        expect { @driver.execute_script "omg" }.to raise_error(JavascriptError)

        begin
          @driver.execute_script "omg"
        rescue JavascriptError => e
          e.message.should include("omg")
          e.message.should include("ReferenceError")
        else
          raise "expected JavascriptError"
        end
      end

      it "doesn't re-raise a Javascript error if it's rescued" do
        begin
          @driver.execute_script "setTimeout(function() { omg }, 0)"
          sleep 0.01
          @driver.execute_script ""
        rescue JavascriptError
        else
          raise "expected JavascriptError"
        end

        # should not raise again
        @driver.evaluate_script("1+1").should == 2
      end

      it 'propagates a Javascript error during page load to a ruby exception' do
        expect { @session.visit "/poltergeist/js_error" }.to raise_error(JavascriptError)
      end

      it "doesn't propagate a Javascript error to ruby if error raising disabled" do
        begin
          driver = Capybara::Poltergeist::Driver.new(@session.app, :js_errors => false, logger: TestSessions.logger)
          driver.visit session_url("/poltergeist/js_error")
          driver.execute_script "setTimeout(function() { omg }, 0)"
          sleep 0.1
          driver.body.should include("hello")
        ensure
          driver.quit if driver
        end
      end
    end

    context "network traffic" do
      before do
        @driver.restart
      end

      it "keeps track of network traffic" do
        @session.visit('/poltergeist/with_js')
        urls = @driver.network_traffic.map(&:url)

        urls.grep(%r{/poltergeist/jquery-1.6.2.min.js$}).size.should == 1
        urls.grep(%r{/poltergeist/jquery-ui-1.8.14.min.js$}).size.should == 1
        urls.grep(%r{/poltergeist/test.js$}).size.should == 1
      end

      it "captures responses" do
        @session.visit('/poltergeist/with_js')
        request = @driver.network_traffic.last

        request.response_parts.last.status.should == 200
      end

      it "keeps a running list between multiple web page views" do
        @session.visit('/poltergeist/with_js')
        @driver.network_traffic.length.should equal(4)

        @session.visit('/poltergeist/with_js')
        @driver.network_traffic.length.should equal(8)
      end

      it "gets cleared on restart" do
        @session.visit('/poltergeist/with_js')
        @driver.network_traffic.length.should equal(4)

        @driver.restart

        @session.visit('/poltergeist/with_js')
        @driver.network_traffic.length.should equal(4)
      end
    end

    context 'status code support' do
      it 'should determine status from the simple response' do
        @session.visit('/poltergeist/status/500')
        @driver.status_code.should == 500
      end

      it 'should determine status code when the page has a few resources' do
        @session.visit('/poltergeist/with_different_resources')
        @driver.status_code.should == 200
      end

      it 'should determine status code even after redirect' do
        @session.visit('/poltergeist/redirect')
        @driver.status_code.should == 200
      end
    end

    context 'cookies support' do
      it 'returns set cookies' do
        @session.visit('/set_cookie')

        cookie = @driver.cookies['capybara']
        cookie.name.should      == 'capybara'
        cookie.value.should     == 'test_cookie'
        cookie.domain.should    == '127.0.0.1'
        cookie.path.should      == '/'
        cookie.secure?.should   == false
        cookie.httponly?.should == false
        cookie.expires.should   == nil
      end

      it 'can set cookies' do
        @driver.set_cookie 'capybara', 'omg'
        @session.visit('/get_cookie')
        @driver.body.should include('omg')
      end

      it 'can set cookies when a space exists in the url' do
        @session.visit '/poltergeist/arbitrary_path/200/foo bar'
        @driver.set_cookie 'capybara', 'omg'
      end

      it 'can set cookies with custom settings' do
        @driver.set_cookie 'capybara', 'omg', :path => '/poltergeist'

        @session.visit('/get_cookie')
        @driver.body.should_not include('omg')

        @session.visit('/poltergeist/get_cookie')
        @driver.body.should include('omg')

        @driver.cookies['capybara'].path.should == '/poltergeist'
      end

      it 'can remove a cookie' do
        @session.visit('/set_cookie')

        @session.visit('/get_cookie')
        @driver.body.should include('test_cookie')

        @driver.remove_cookie 'capybara'

        @session.visit('/get_cookie')
        @driver.body.should_not include('test_cookie')
      end

      it 'can set cookies with an expires time' do
        time = Time.at(Time.now.to_i + 10000)
        @session.visit '/'
        @driver.set_cookie 'foo', 'bar', :expires => time
        @driver.cookies['foo'].expires.should == time
      end

      it 'can set cookies for given domain' do
        port = @session.server.port
        @driver.set_cookie 'capybara', '127.0.0.1'
        @driver.set_cookie 'capybara', 'localhost', :domain => 'localhost'

        @session.visit("http://localhost:#{port}/poltergeist/get_cookie")
        @driver.body.should include('localhost')

        @session.visit("http://127.0.0.1:#{port}/poltergeist/get_cookie")
        @driver.body.should include('127.0.0.1')
      end

      it 'can enable and disable cookies' do
        @driver.cookies_enabled = false
        @session.visit('/set_cookie')
        @driver.cookies.should be_empty

        @driver.cookies_enabled = true
        @session.visit('/set_cookie')
        @driver.cookies.should_not be_empty
      end
    end

    it "allows the driver to have a fixed port" do
      begin
        driver = Capybara::Poltergeist::Driver.new(@driver.app, port: 12345)
        driver.visit session_url('/')

        expect { TCPServer.new("127.0.0.1", 12345) }.to raise_error(Errno::EADDRINUSE)
      ensure
        driver.quit
      end
    end

    it 'lists the open windows' do
      @session.visit '/'

      @session.evaluate_script <<-CODE
          window.open('/poltergeist/simple', 'popup')
      CODE

      @session.evaluate_script <<-CODE
          window.open('/poltergeist/simple', 'popup2')
      CODE

      @session.within_window 'popup2' do
        @session.html.should include('Test')
        @session.evaluate_script('window.close()')
      end

      sleep 0.1;

      @driver.browser.window_handles.should == ["popup"]
      @driver.window_handles.should == ["popup"]
    end

  end
end
