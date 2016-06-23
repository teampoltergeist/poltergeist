require 'spec_helper'
require 'image_size'
require 'pdf/reader'

module Capybara::Poltergeist
  describe Driver do
    before do
      @session = TestSessions::Poltergeist
      @driver = @session.driver
    end

    after { @driver.reset! }

    def session_url(path)
      server = @session.server
      "http://#{server.host}:#{server.port}#{path}"
    end

    it 'supports a custom phantomjs path' do
      begin
        file = POLTERGEIST_ROOT + '/spec/support/custom_phantomjs_called'
        path = POLTERGEIST_ROOT + '/spec/support/custom_phantomjs'

        FileUtils.rm_f file

        driver = Capybara::Poltergeist::Driver.new(nil, phantomjs: path)
        driver.browser

        # If the correct custom path is called, it will touch the file.
        # We allow at least 10 secs for this to happen before failing.

        tries = 0
        until File.exist?(file) || tries == 100
          sleep 0.1
          tries += 1
        end

        expect(File.exist?(file)).to be true
      ensure
        driver.quit if driver
      end
    end

    it 'supports capturing console.log' do
      begin
        output = StringIO.new
        Capybara.register_driver :poltergeist_with_logger do |app|
          Capybara::Poltergeist::Driver.new(app, phantomjs_logger: output)
        end

        session = Capybara::Session.new(:poltergeist_with_logger, TestApp)
        session.visit('/poltergeist/console_log')
        expect(output.string).to include('Hello world')
      ensure
        session.driver.quit
      end
    end

    it 'raises an error and restarts the client if the client dies while executing a command' do
      expect { @driver.browser.command('exit') }.to raise_error(DeadClient)
      @session.visit('/')
      expect(@driver.html).to include('Hello world')
    end

    it 'quits silently before visit call' do
      driver = Capybara::Poltergeist::Driver.new(nil)
      expect { driver.quit }.not_to raise_error
    end

    it 'has a viewport size of 1024x768 by default' do
      @session.visit('/')
      expect(
        @driver.evaluate_script('[window.innerWidth, window.innerHeight]')
      ).to eq([1024, 768])
    end

    it 'allows the viewport to be resized' do
      @session.visit('/')
      @driver.resize(200, 400)
      expect(
        @driver.evaluate_script('[window.innerWidth, window.innerHeight]')
      ).to eq([200, 400])
    end

    it 'allows the page to be scrolled' do
      @session.visit('/poltergeist/long_page')
      @driver.resize(10, 10)
      @driver.scroll_to(200, 100)
      expect(
        @driver.evaluate_script('[window.scrollX, window.scrollY]')
      ).to eq([200, 100])
    end

    it 'supports specifying viewport size with an option' do
      begin
        Capybara.register_driver :poltergeist_with_custom_window_size do |app|
          Capybara::Poltergeist::Driver.new(
            app,
            logger: TestSessions.logger,
            window_size: [800, 600]
          )
        end
        driver = Capybara::Session.new(:poltergeist_with_custom_window_size, TestApp).driver
        driver.visit(session_url '/')
        expect(
          driver.evaluate_script('[window.innerWidth, window.innerHeight]')
        ).to eq([800, 600])
      ensure
        driver.quit if driver
      end
    end

    shared_examples 'render screen' do
      it 'supports rendering the whole of a page that goes outside the viewport' do
        @session.visit('/poltergeist/long_page')

        create_screenshot file
        File.open(file, 'rb') do |f|
          expect(ImageSize.new(f.read).size).to eq(
            @driver.evaluate_script('[window.innerWidth, window.innerHeight]')
          )
        end

        create_screenshot file, full: true
        File.open(file, 'rb') do |f|
          expect(ImageSize.new(f.read).size).to eq(
            @driver.evaluate_script('[document.documentElement.clientWidth, document.documentElement.clientHeight]')
          )
        end
      end

      it 'supports rendering the entire window when documentElement has no height' do
        @session.visit('/poltergeist/fixed_positioning')

        create_screenshot file, full: true
        File.open(file, 'rb') do |f|
          expect(ImageSize.new(f.read).size).to eq(
            @driver.evaluate_script('[window.innerWidth, window.innerHeight]')
          )
        end
      end

      it 'supports rendering just the selected element' do
        @session.visit('/poltergeist/long_page')

        create_screenshot file, selector: '#penultimate'

        File.open(file, 'rb') do |f|
          size = @driver.evaluate_script <<-EOS
            function() {
              var ele  = document.getElementById('penultimate');
              var rect = ele.getBoundingClientRect();
              return [rect.width, rect.height];
            }();
          EOS
          expect(ImageSize.new(f.read).size).to eq(size)
        end
      end

      it 'ignores :selector in #save_screenshot if full: true' do
        @session.visit('/poltergeist/long_page')
        expect(@driver.browser).to receive(:warn).with(/Ignoring :selector/)

        create_screenshot file, full: true, selector: '#penultimate'

        File.open(file, 'rb') do |f|
          expect(ImageSize.new(f.read).size).to eq(
            @driver.evaluate_script('[document.documentElement.clientWidth, document.documentElement.clientHeight]')
          )
        end
      end
    end

    describe '#save_screenshot' do
      let(:format) { :png }
      let(:file) { POLTERGEIST_ROOT + "/spec/tmp/screenshot.#{format}" }

      before(:each) { FileUtils.rm_f file }

      def create_screenshot(file, *args)
        @driver.save_screenshot(file, *args)
      end

      it 'supports rendering the page' do
        @session.visit('/')

        @driver.save_screenshot(file)

        expect(File.exist?(file)).to be true
      end

      it 'supports rendering the page with a nonstring path' do
        @session.visit('/')

        @driver.save_screenshot(Pathname(file))

        expect(File.exist?(file)).to be true
      end

      it 'supports rendering the page to file without extension when format is specified' do
        begin
          file = POLTERGEIST_ROOT + "/spec/tmp/screenshot"
          FileUtils.rm_f file
          @session.visit('/')

          @driver.save_screenshot(file, format: 'jpg')

          expect(File.exist?(file)).to be true
        ensure
          FileUtils.rm_f file
        end
      end

      it 'supports rendering the page with different quality settings' do
        file2 = POLTERGEIST_ROOT + "/spec/tmp/screenshot2.#{format}"
        file3 = POLTERGEIST_ROOT + "/spec/tmp/screenshot3.#{format}"
        FileUtils.rm_f [file2, file3]

        begin
          @session.visit('/')
          @driver.save_screenshot(file, quality: 0)
          @driver.save_screenshot(file2) # phantomjs defaults to a quality of 75
          @driver.save_screenshot(file3, quality: 100)
          expect(File.size(file)).to be < File.size(file2)
          expect(File.size(file2)).to be < File.size(file3)
        ensure
          FileUtils.rm_f [file2, file3]
        end
      end

      shared_examples 'when #zoom_factor= is set' do
        let(:format) { :xbm }

        it 'changes image dimensions' do
          @session.visit('/poltergeist/zoom_test')

          black_pixels_count = ->(file) {
            File.read(file).to_s[/{.*}/m][1...-1].split(/\W/).map{|n| n.hex.to_s(2).count('1')}.reduce(:+)
          }
          @driver.save_screenshot(file)
          before = black_pixels_count[file]

          @driver.zoom_factor = zoom_factor
          @driver.save_screenshot(file)
          after = black_pixels_count[file]

          expect(after.to_f/before.to_f).to eq(zoom_factor**2)
        end
      end

      context 'zoom in' do
        let(:zoom_factor) { 2 }
        include_examples 'when #zoom_factor= is set'
      end

      context 'zoom out' do
        let(:zoom_factor) { 0.5 }
        include_examples 'when #zoom_factor= is set'
      end

      context 'when #paper_size= is set' do
        let(:format) { :pdf }

        it 'changes pdf size' do
          @session.visit('/poltergeist/long_page')
          @driver.paper_size = { width: '1in', height: '1in' }

          @driver.save_screenshot(file)

          reader = PDF::Reader.new(file)
          reader.pages.each do |page|
            bbox   = page.attributes[:MediaBox]
            width  = (bbox[2] - bbox[0]) / 72
            expect(width).to eq(1)
          end
        end
      end

      include_examples 'render screen'
    end

    describe '#render_base64' do
      let(:file) { POLTERGEIST_ROOT + "/spec/tmp/screenshot.#{format}" }

      def create_screenshot(file, *args)
        image = @driver.render_base64(format, *args)
        File.open(file, 'wb') { |f| f.write Base64.decode64(image) }
      end

      it 'supports rendering the page in base64' do
        @session.visit('/')

        screenshot = @driver.render_base64

        expect(screenshot.length).to be > 100
      end

      context 'png' do
        let(:format) { :png }
        include_examples 'render screen'
      end

      context 'jpeg' do
        let(:format) { :jpeg }
        include_examples 'render screen'
      end
    end

    context 'setting headers' do
      it 'allows headers to be set' do
        @driver.headers = {
          'Cookie' => 'foo=bar',
          'Host' => 'foo.com'
        }
        @session.visit('/poltergeist/headers')
        expect(@driver.body).to include('COOKIE: foo=bar')
        expect(@driver.body).to include('HOST: foo.com')
      end

      it 'allows headers to be read' do
        expect(@driver.headers).to eq({})
        @driver.headers = { 'User-Agent' => 'PhantomJS', 'Host' => 'foo.com' }
        expect(@driver.headers).to eq('User-Agent' => 'PhantomJS', 'Host' => 'foo.com')
      end

      it 'supports User-Agent' do
        @driver.headers = { 'User-Agent' => 'foo' }
        @session.visit '/'
        expect(@driver.evaluate_script('window.navigator.userAgent')).to eq('foo')
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
        expect(@driver.body).to include('X_OMG: wat')
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
        expect(ajax_request).to_not include('REFERER: http://google.com')
        expect(ajax_request).to_not include('TEMPA: a')
      end
    end

    it 'supports clicking precise coordinates' do
      @session.visit('/poltergeist/click_coordinates')
      @driver.click(100, 150)
      expect(@driver.body).to include('x: 100, y: 150')
    end

    it 'supports executing multiple lines of javascript' do
      @driver.execute_script <<-JS
        var a = 1
        var b = 2
        window.result = a + b
      JS
      expect(@driver.evaluate_script('result')).to eq(3)
    end

    it 'operates a timeout when communicating with phantomjs' do
      begin
        prev_timeout = @driver.timeout
        @driver.timeout = 0.001
        expect { @driver.browser.command 'noop' }.to raise_error(TimeoutError)
      ensure
        @driver.timeout = prev_timeout
      end
    end

    unless Capybara::Poltergeist.windows?
      # Not sure how to do this on Windows, so skipping
      it 'supports quitting the session' do
        driver = Capybara::Poltergeist::Driver.new(nil)
        pid    = driver.client_pid

        expect(Process.kill(0, pid)).to eq(1)
        driver.quit

        expect { Process.kill(0, pid) }.to raise_error(Errno::ESRCH)
      end
    end

    context 'extending browser javascript' do
      before do
        @extended_driver = Capybara::Poltergeist::Driver.new(
          @session.app,
          logger: TestSessions.logger,
          inspector: ENV['DEBUG'] != nil,
          extensions: %W% #{File.expand_path '../../support/geolocation.js', __FILE__ } %
        )
      end

      it 'supports extending the phantomjs world' do
        begin
          @extended_driver.visit session_url('/poltergeist/requiring_custom_extension')
          expect(@extended_driver.body).
            to include(%Q%Location: <span id="location">1,-1</span>%)
          expect(
            @extended_driver.evaluate_script("document.getElementById('location').innerHTML")
          ).to eq('1,-1')
          expect(
            @extended_driver.evaluate_script('navigator.geolocation')
          ).to_not eq(nil)
        ensure
          @extended_driver.quit
        end
      end
    end

    context 'javascript errors' do
      it 'propagates a Javascript error inside Poltergeist to a ruby exception' do
        expect {
          @driver.browser.command 'browser_error'
        }.to raise_error(BrowserError) { |e|
          expect(e.message).to include('Error: zomg')
          # PhantomJS 2.1 refers to files as being in code subdirectory
          expect(e.message).to include('compiled/browser.js').or include('code/browser.js')
        }
      end

      it 'propagates an asynchronous Javascript error on the page to a ruby exception' do
        expect {
          @driver.execute_script 'setTimeout(function() { omg }, 0)'
          sleep 0.01
          @driver.execute_script ''
        }.to raise_error(JavascriptError, /ReferenceError.*omg/)
      end

      it 'propagates a synchronous Javascript error on the page to a ruby exception' do
        expect {
          @driver.execute_script 'omg'
        }.to raise_error(JavascriptError, /ReferenceError.*omg/)
      end

      it 'does not re-raise a Javascript error if it is rescued' do
        expect {
          @driver.execute_script 'setTimeout(function() { omg }, 0)'
          sleep 0.01
          @driver.execute_script ''
        }.to raise_error(JavascriptError)

        # should not raise again
        expect(@driver.evaluate_script('1+1')).to eq(2)
      end

      it 'propagates a Javascript error during page load to a ruby exception' do
        expect { @session.visit '/poltergeist/js_error' }.to raise_error(JavascriptError)
      end

      it 'does not propagate a Javascript error to ruby if error raising disabled' do
        begin
          driver = Capybara::Poltergeist::Driver.new(@session.app, js_errors: false, logger: TestSessions.logger)
          driver.visit session_url('/poltergeist/js_error')
          driver.execute_script 'setTimeout(function() { omg }, 0)'
          sleep 0.1
          expect(driver.body).to include('hello')
        ensure
          driver.quit if driver
        end
      end

      it 'does not propagate a Javascript error to ruby if error raising disabled and client restarted' do
        begin
          driver = Capybara::Poltergeist::Driver.new(@session.app, js_errors: false, logger: TestSessions.logger)
          driver.restart
          driver.visit session_url('/poltergeist/js_error')
          driver.execute_script 'setTimeout(function() { omg }, 0)'
          sleep 0.1
          expect(driver.body).to include('hello')
        ensure
          driver.quit if driver
        end
      end
    end

    context "phantomjs {'status': 'fail'} responses" do
      before { @port = @session.server.port }

      it 'do not occur when DNS correct' do
        expect { @session.visit("http://localhost:#{@port}/") }.not_to raise_error
      end

      it 'handles when DNS incorrect' do
        expect { @session.visit("http://nope:#{@port}/") }.to raise_error(StatusFailError)
      end

      it 'has a descriptive message when DNS incorrect' do
        url = "http://nope:#{@port}/"
        expect {
          @session.visit(url)
        }.to raise_error(StatusFailError, "Request to '#{url}' failed to reach server, check DNS and/or server status")
      end

      it 'reports open resource requests' do
        old_timeout = @session.driver.timeout
        begin
          @session.driver.timeout = 2
          expect{
            @session.visit('/poltergeist/visit_timeout')
          }.to raise_error(StatusFailError, /resources still waiting http:\/\/.*\/poltergeist\/really_slow/)
        ensure
          @session.driver.timeout = old_timeout
        end
      end

      it 'doesnt report open resources where there are none' do
        old_timeout = @session.driver.timeout
        begin
          @session.driver.timeout = 2
          expect{
            @session.visit('/poltergeist/really_slow')
          }.to raise_error(StatusFailError) {|error|
            expect(error.message).not_to include('resources still waiting')
          }
        ensure
          @session.driver.timeout = old_timeout
        end
      end
    end

    context 'network traffic' do
      before do
        @driver.restart
      end

      it 'keeps track of network traffic' do
        @session.visit('/poltergeist/with_js')
        urls = @driver.network_traffic.map(&:url)

        expect(urls.grep(%r{/poltergeist/jquery.min.js$}).size).to eq(1)
        expect(urls.grep(%r{/poltergeist/jquery-ui.min.js$}).size).to eq(1)
        expect(urls.grep(%r{/poltergeist/test.js$}).size).to eq(1)
      end

      it 'captures responses' do
        @session.visit('/poltergeist/with_js')
        request = @driver.network_traffic.last

        expect(request.response_parts.last.status).to eq(200)
      end

      it 'captures errors' do
        @session.visit('/poltergeist/with_ajax_fail')
        expect(@session).to have_css('h1', text: 'Done')
        error = @driver.network_traffic.last.error

        expect(error).to be
      end

      it 'keeps a running list between multiple web page views' do
        @session.visit('/poltergeist/with_js')
        expect(@driver.network_traffic.length).to eq(4)

        @session.visit('/poltergeist/with_js')
        expect(@driver.network_traffic.length).to eq(8)
      end

      it 'gets cleared on restart' do
        @session.visit('/poltergeist/with_js')
        expect(@driver.network_traffic.length).to eq(4)

        @driver.restart

        @session.visit('/poltergeist/with_js')
        expect(@driver.network_traffic.length).to eq(4)
      end

      it 'gets cleared when being cleared' do
        @session.visit('/poltergeist/with_js')
        expect(@driver.network_traffic.length).to eq(4)

        @driver.clear_network_traffic

        expect(@driver.network_traffic.length).to eq(0)
      end
    end

    context "memory cache clearing" do

      before do
        @driver.restart
      end

      it "can clear memory cache when supported (phantomjs >=2.0.0)" do
        skip "clear_memory_cache is not supported by tested PhantomJS" unless phantom_version_is? ">= 2.0.0", @driver

        @driver.clear_memory_cache

        @session.visit('/poltergeist/cacheable')
        first_request = @driver.network_traffic.last
        expect(@driver.network_traffic.length).to eq(1)
        expect(first_request.response_parts.last.status).to eq(200)

        @session.visit('/poltergeist/cacheable')
        expect(@driver.network_traffic.length).to eq(1)

        @driver.clear_memory_cache

        @session.visit('/poltergeist/cacheable')
        another_request = @driver.network_traffic.last
        expect(@driver.network_traffic.length).to eq(2)
        expect(another_request.response_parts.last.status).to eq(200)
      end

      it "raises error when it is unsupported (phantomjs <2.0.0)" do
        skip "clear_memory_cache is supported by tested PhantomJS" if phantom_version_is? ">= 2.0.0", @driver

        @session.visit('/poltergeist/cacheable')
        first_request = @driver.network_traffic.last
        expect(@driver.network_traffic.length).to eq(1)
        expect(first_request.response_parts.last.status).to eq(200)

        expect{@driver.clear_memory_cache}.to raise_error(Capybara::Poltergeist::UnsupportedFeature)

        @session.visit('/poltergeist/cacheable')
        expect(@driver.network_traffic.length).to eq(2)
      end
    end

    context 'status code support' do
      it 'determines status from the simple response' do
        @session.visit('/poltergeist/status/500')
        expect(@driver.status_code).to eq(500)
      end

      it 'determines status code when the page has a few resources' do
        @session.visit('/poltergeist/with_different_resources')
        expect(@driver.status_code).to eq(200)
      end

      it 'determines status code even after redirect' do
        @session.visit('/poltergeist/redirect')
        expect(@driver.status_code).to eq(200)
      end
    end

    context 'cookies support' do
      it 'returns set cookies' do
        @session.visit('/set_cookie')

        cookie = @driver.cookies['capybara']
        expect(cookie.name).to eq('capybara')
        expect(cookie.value).to eq('test_cookie')
        expect(cookie.domain).to eq('127.0.0.1')
        expect(cookie.path).to eq('/')
        expect(cookie.secure?).to be false
        expect(cookie.httponly?).to be false
        expect(cookie.samesite).to be_nil
        expect(cookie.expires).to be_nil
      end

      it 'can set cookies' do
        @driver.set_cookie 'capybara', 'omg'
        @session.visit('/get_cookie')
        expect(@driver.body).to include('omg')
      end

      it 'can set cookies with custom settings' do
        @driver.set_cookie 'capybara', 'omg', path: '/poltergeist'

        @session.visit('/get_cookie')
        expect(@driver.body).to_not include('omg')

        @session.visit('/poltergeist/get_cookie')
        expect(@driver.body).to include('omg')

        expect(@driver.cookies['capybara'].path).to eq('/poltergeist')
      end

      it 'can remove a cookie' do
        @session.visit('/set_cookie')

        @session.visit('/get_cookie')
        expect(@driver.body).to include('test_cookie')

        @driver.remove_cookie 'capybara'

        @session.visit('/get_cookie')
        expect(@driver.body).to_not include('test_cookie')
      end

      it 'can clear cookies' do
        @session.visit('/set_cookie')

        @session.visit('/get_cookie')
        expect(@driver.body).to include('test_cookie')

        @driver.clear_cookies

        @session.visit('/get_cookie')
        expect(@driver.body).to_not include('test_cookie')
      end

      it 'can set cookies with an expires time' do
        time = Time.at(Time.now.to_i + 10000)
        @session.visit '/'
        @driver.set_cookie 'foo', 'bar', expires: time
        expect(@driver.cookies['foo'].expires).to eq(time)
      end

      it 'can set cookies for given domain' do
        port = @session.server.port
        @driver.set_cookie 'capybara', '127.0.0.1'
        @driver.set_cookie 'capybara', 'localhost', domain: 'localhost'

        @session.visit("http://localhost:#{port}/poltergeist/get_cookie")
        expect(@driver.body).to include('localhost')

        @session.visit("http://127.0.0.1:#{port}/poltergeist/get_cookie")
        expect(@driver.body).to include('127.0.0.1')
      end

      it 'can enable and disable cookies' do
        @driver.cookies_enabled = false
        @session.visit('/set_cookie')
        expect(@driver.cookies).to be_empty

        @driver.cookies_enabled = true
        @session.visit('/set_cookie')
        expect(@driver.cookies).to_not be_empty
      end

      it 'sets cookies correctly when Capybara.app_host is set' do
        old_app_host = Capybara.app_host
        begin
          Capybara.app_host = 'http://localhost/poltergeist'
          @driver.set_cookie 'capybara', 'app_host'

          port = @session.server.port
          @session.visit("http://localhost:#{port}/poltergeist/get_cookie")
          expect(@driver.body).to include('app_host')

          @session.visit("http://127.0.0.1:#{port}/poltergeist/get_cookie")
          expect(@driver.body).not_to include('app_host')
        ensure
          Capybara.app_host = old_app_host
        end
      end
    end

    it 'allows the driver to have a fixed port' do
      begin
        driver = Capybara::Poltergeist::Driver.new(@driver.app, port: 12345)
        driver.visit session_url('/')

        expect { TCPServer.new('127.0.0.1', 12345) }.to raise_error(Errno::EADDRINUSE)
      ensure
        driver.quit
      end
    end

    it 'lists the open windows' do
      @session.visit '/'

      @session.execute_script <<-JS
        window.open('/poltergeist/simple', 'popup')
      JS

      expect(@driver.window_handles).to eq(['0', '1'])

      popup2 = @session.window_opened_by do
        @session.execute_script <<-JS
          window.open('/poltergeist/simple', 'popup2')
        JS
      end

      expect(@driver.window_handles).to eq(['0', '1', '2'])

      @session.within_window(popup2) do
        expect(@session.html).to include('Test')
        @session.execute_script('window.close()')
      end

      sleep 0.1;

      expect(@driver.window_handles).to eq(['0', '1'])
    end

    context 'a new window inherits settings' do
      it 'inherits size' do
        @session.visit '/'
        @session.current_window.resize_to(1200,800)
        new_tab = @session.open_new_window
        expect(new_tab.size).to eq [1200,800]
      end

      it 'inherits url_blacklist' do
        @driver.browser.url_blacklist = ['unwanted']
        @session.visit '/'
        new_tab = @session.open_new_window
        @session.within_window(new_tab) do
          @session.visit '/poltergeist/url_blacklist'
          expect(@session).to have_content('We are loading some unwanted action here')
          @session.within_frame 'framename' do
            expect(@session.html).not_to include('We shouldn\'t see this.')
          end
        end
      end

      it 'inherits url_whitelist' do
        @session.visit '/'
        @driver.browser.url_whitelist = ['url_whitelist', '/poltergeist/wanted']
        new_tab = @session.open_new_window
        @session.within_window(new_tab) do
          @session.visit '/poltergeist/url_whitelist'

          expect(@session).to have_content('We are loading some wanted action here')
          @session.within_frame 'framename' do
            expect(@session).to have_content('We should see this.')
          end
          @session.within_frame 'unwantedframe' do
            #make sure non whitelisted urls are blocked
            expect(@session).not_to have_content("We shouldn't see this.")
          end
        end
      end
    end


    it 'resizes windows' do
      @session.visit '/'

      popup1 = @session.window_opened_by do
        @session.execute_script <<-JS
          window.open('/poltergeist/simple', 'popup1')
        JS
      end

      popup2 = @session.window_opened_by do
        @session.execute_script <<-JS
          window.open('/poltergeist/simple', 'popup2')
        JS
      end

      popup1.resize_to(100,200)
      popup2.resize_to(200,100)

      expect(popup1.size).to eq([100,200])
      expect(popup2.size).to eq([200,100])
    end

    it 'clears local storage between tests' do
      @session.visit '/'
      @session.execute_script <<-JS
        localStorage.setItem('key', 'value');
      JS
      value = @session.evaluate_script <<-JS
        localStorage.getItem('key');
      JS

      expect(value).to eq('value')

      @driver.reset!

      @session.visit '/'
      value = @session.evaluate_script <<-JS
        localStorage.getItem('key');
      JS
      expect(value).to be_nil
    end

    context 'basic http authentication' do
      it 'denies without credentials' do
        @session.visit '/poltergeist/basic_auth'

        expect(@session.status_code).to eq(401)
        expect(@session).not_to have_content('Welcome, authenticated client')
      end

      it 'allows with given credentials' do
        @driver.basic_authorize('login', 'pass')

        @session.visit '/poltergeist/basic_auth'

        expect(@session.status_code).to eq(200)
        expect(@session).to have_content('Welcome, authenticated client')
      end

      it 'allows even overwriting headers' do
        @driver.basic_authorize('login', 'pass')
        @driver.headers = [{ 'Poltergeist' => 'true' }]

        @session.visit '/poltergeist/basic_auth'

        expect(@session.status_code).to eq(200)
        expect(@session).to have_content('Welcome, authenticated client')
      end

      it 'denies with wrong credentials' do
        @driver.basic_authorize('user', 'pass!')

        @session.visit '/poltergeist/basic_auth'

        expect(@session.status_code).to eq(401)
        expect(@session).not_to have_content('Welcome, authenticated client')
      end

      it 'allows on POST request' do
        @driver.basic_authorize('login', 'pass')

        @session.visit '/poltergeist/basic_auth'
        @session.click_button('Submit')

        expect(@session.status_code).to eq(200)
        expect(@session).to have_content('Authorized POST request')
      end
    end

    context 'blacklisting urls for resource requests' do
      it 'blocks unwanted urls' do
        @driver.browser.url_blacklist = ['unwanted']

        @session.visit '/poltergeist/url_blacklist'

        expect(@session.status_code).to eq(200)
        expect(@session).to have_content('We are loading some unwanted action here')
        @session.within_frame 'framename' do
          expect(@session.html).not_to include('We shouldn\'t see this.')
        end
      end

      it 'can be configured in the driver and survive reset' do
        Capybara.register_driver :poltergeist_blacklist do |app|
          Capybara::Poltergeist::Driver.new(app, @driver.options.merge(url_blacklist: ['unwanted']))
        end

        session = Capybara::Session.new(:poltergeist_blacklist, @session.app)

        session.visit '/poltergeist/url_blacklist'
        expect(session).to have_content('We are loading some unwanted action here')
        session.within_frame 'framename' do
          expect(session.html).not_to include('We shouldn\'t see this.')
        end

        session.reset!

        session.visit '/poltergeist/url_blacklist'
        expect(session).to have_content('We are loading some unwanted action here')
        session.within_frame 'framename' do
          expect(session.html).not_to include('We shouldn\'t see this.')
        end
      end
    end

    context 'whitelisting urls for resource requests' do
      it 'allows whitelisted urls' do
        @driver.browser.url_whitelist = ['url_whitelist', 'wanted']

        @session.visit '/poltergeist/url_whitelist'

        expect(@session.status_code).to eq(200)
        expect(@session).to have_content('We are loading some wanted action here')
        @session.within_frame 'framename' do
          expect(@session).to have_content('We should see this.')
        end
      end

      it 'blocks overruled urls' do
        @driver.browser.url_whitelist = ['url_whitelist']
        @driver.browser.url_blacklist = ['url_whitelist']

        @session.visit '/poltergeist/url_whitelist'

        expect(@session.status_code).to eq(nil)
        expect(@session).not_to have_content('We are loading some wanted action here')
      end

      it 'allows urls when the whitelist is empty' do
        @driver.browser.url_whitelist = []

        @session.visit '/poltergeist/url_whitelist'

        expect(@session.status_code).to eq(200)
        expect(@session).to have_content('We are loading some wanted action here')
        @session.within_frame 'framename' do
          expect(@session).to have_content('We should see this.')
        end
      end

      it 'can be configured in the driver and survive reset' do
        Capybara.register_driver :poltergeist_whitelist do |app|
          Capybara::Poltergeist::Driver.new(app, @driver.options.merge(url_whitelist: ['url_whitelist', '/poltergeist/wanted']))
        end

        session = Capybara::Session.new(:poltergeist_whitelist, @session.app)

        session.visit '/poltergeist/url_whitelist'
        expect(session).to have_content('We are loading some wanted action here')
        session.within_frame 'framename' do
          expect(session).to have_content('We should see this.')
        end

        session.within_frame 'unwantedframe' do
          #make sure non whitelisted urls are blocked
          expect(session).not_to have_content("We shouldn't see this.")
        end

        session.reset!

        session.visit '/poltergeist/url_whitelist'
        expect(session).to have_content('We are loading some wanted action here')
        session.within_frame 'framename' do
          expect(session).to have_content('We should see this.')
        end
        session.within_frame 'unwantedframe' do
          #make sure non whitelisted urls are blocked
          expect(session).not_to have_content("We shouldn't see this.")
        end
      end
    end


    context 'has ability to send keys' do
      before { @session.visit('/poltergeist/send_keys') }

      it 'sends keys to empty input' do
        input = @session.find(:css, '#empty_input')

        input.native.send_keys('Input')

        expect(input.value).to eq('Input')
      end

      it 'sends keys to filled input' do
        input = @session.find(:css, '#filled_input')

        input.native.send_keys(' appended')

        expect(input.value).to eq('Text appended')
      end

      it 'sends keys to empty textarea' do
        input = @session.find(:css, '#empty_textarea')

        input.native.send_keys('Input')

        expect(input.value).to eq('Input')
      end

      it 'sends keys to filled textarea' do
        input = @session.find(:css, '#filled_textarea')

        input.native.send_keys(' appended')

        expect(input.value).to eq('Description appended')
      end

      it 'sends keys to empty contenteditable div' do
        input = @session.find(:css, '#empty_div')

        input.native.send_keys('Input')

        expect(input.text).to eq('Input')
      end

      it 'persists focus across calls' do
        input = @session.find(:css, '#empty_div')

        input.native.send_keys('helo')
        input.native.send_keys(:Left)
        input.native.send_keys('l')

        expect(input.text).to eq('hello')
      end

      it 'sends keys to filled contenteditable div' do
        input = @session.find(:css, '#filled_div')

        input.native.send_keys(' appended')

        expect(input.text).to eq('Content appended')
      end

      it 'sends sequences' do
        input = @session.find(:css, '#empty_input')

        input.native.send_keys(:Shift, 'S', :Alt, 't', 'r', 'i', 'g', :Left, 'n')

        expect(input.value).to eq('String')
      end

      it 'submits the form with sequence' do
        input = @session.find(:css, '#without_submit_button input')

        input.native.send_keys(:Enter)

        expect(input.value).to eq('Submitted')
      end

      it 'sends sequences with modifiers and letters' do
        input = @session.find(:css, '#empty_input')

        input.native.send_keys([:Shift, 's'], 't', 'r', 'i', 'n', 'g')

        expect(input.value).to eq('String')
      end

      it 'sends sequences with modifiers and symbols' do
        input = @session.find(:css, '#empty_input')

        input.native.send_keys('t', 'r', 'i', 'n', 'g', [:Ctrl, :Left], 's')

        expect(input.value).to eq('string')
      end

      it 'sends sequences with multiple modifiers and symbols' do
        input = @session.find(:css, '#empty_input')

        input.native.send_keys('t', 'r', 'i', 'n', 'g', [:Ctrl, :Shift, :Left], 's')

        expect(input.value).to eq('s')
      end

      it 'has an alias' do
        input = @session.find(:css, '#empty_input')

        input.native.send_key('S')

        expect(input.value).to eq('S')
      end
    end

    context 'set' do
      before { @session.visit('/poltergeist/set') }

      it "sets a contenteditable's content" do
        input = @session.find(:css, '#filled_div')
        input.set('new text')
        expect(input.text).to eq('new text')
      end

      it "sets multiple contenteditables' content" do
        input = @session.find(:css, '#empty_div')
        input.set('new text')

        expect(input.text).to eq('new text')

        input = @session.find(:css, '#filled_div')
        input.set('replacement text')

        expect(input.text).to eq('replacement text')
      end
    end

    context 'date_fields' do
      before { @session.visit('/poltergeist/date_fields') }

      it 'sets a date' do
        input = @session.find(:css, '#date_field')

        input.set('2016-02-14')

        expect(input.value).to eq('2016-02-14')
      end

      it 'fills a date' do
        @session.fill_in 'date_field', with: '2016-02-14'

        expect(@session.find(:css, '#date_field').value).to eq('2016-02-14')
      end
    end
  end
end
