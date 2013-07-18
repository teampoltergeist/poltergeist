require 'spec_helper'

Capybara::SpecHelper.run_specs TestSessions::Poltergeist, "Poltergeist"

describe Capybara::Session do
  context 'with poltergeist driver' do
    before do
      @session = TestSessions::Poltergeist
    end

    describe Capybara::Poltergeist::Node do
      it 'raises an error if the element has been removed from the DOM' do
        @session.visit('/poltergeist/with_js')
        node = @session.find(:css, '#remove_me')
        node.text.should == 'Remove me'
        @session.find(:css, '#remove').click
        lambda { node.text }.should raise_error(Capybara::Poltergeist::ObsoleteNode)
      end

      it 'raises an error if the element was on a previous page' do
        @session.visit('/poltergeist/index')
        node = @session.find('.//a')
        @session.execute_script "window.location = 'about:blank'"
        expect { node.text }.to raise_error(Capybara::Poltergeist::ObsoleteNode)
      end

      it 'raises an error if the element is not visible' do
        @session.visit('/poltergeist/index')
        @session.execute_script "document.querySelector('a[href=js_redirect]').style.display = 'none'"
        expect { @session.click_link "JS redirect" }.to raise_error(Capybara::ElementNotFound)
      end

      it 'hovers an element' do
        @session.visit('/poltergeist/with_js')
        expect(@session.find(:css, '#hidden_link span', :visible => false)).to_not be_visible
        @session.find(:css, '#hidden_link').hover
        expect(@session.find(:css, '#hidden_link span')).to be_visible
      end

      it 'hovers an element before clicking it' do
        @session.visit('/poltergeist/with_js')
        @session.click_link "Hidden link"
        @session.current_path.should == '/'
      end

      it "doesn't raise error when asserting svg elements with a count that is not what is in the dom" do
        @session.visit('/poltergeist/with_js')
        expect { @session.has_css?('svg circle', count: 2) }.to_not raise_error
        @session.should_not have_css('svg circle', count: 2)
      end

      context "when someone (*cough* prototype *cough*) messes with Array#toJSON" do
        before do
          @session.visit("/poltergeist/index")
          array_munge = <<-EOS
          Array.prototype.toJSON = function() {
            return "ohai";
          }
          EOS
          @session.execute_script array_munge
        end

        it "gives a proper error" do
          expect { @session.find(:css, "username") }.to raise_error(Capybara::ElementNotFound)
        end
      end

      context "when the element is not in the viewport" do
        before do
          @session.visit("/poltergeist/with_js")
        end

        it "raises a MouseEventFailed error" do
          expect { @session.click_link("O hai") }.to raise_error(Capybara::Poltergeist::MouseEventFailed)
        end

        context "and is then brought in" do
          before do
            @session.execute_script "$('#off-the-left').animate({left: '10'});"
            Capybara.default_wait_time = 1 #we need capybara to retry until animation finished
          end

          it "clicks properly" do
            expect { @session.click_link "O hai" }.not_to raise_error
          end

          after do
            Capybara.default_wait_time = 0
          end
        end
      end
    end

    context "when the element is not in the viewport of parent element" do
      before do
        @session.visit("/poltergeist/scroll")
      end

      it "scrolls into view" do
        @session.click_link "Link outside viewport"
        @session.current_path.should eq '/'
      end
    end

    describe 'Node#set' do
      before do
        @session.visit('/poltergeist/with_js')
        @session.find(:css, '#change_me').set("Hello!")
      end

      it 'fires the change event' do
        @session.find(:css, '#changes').text.should == "Hello!"
      end

      it 'fires the input event' do
        @session.find(:css, '#changes_on_input').text.should == "Hello!"
      end

      it 'accepts numbers in a maxlength field' do
        element = @session.find(:css, '#change_me_maxlength')
        element.set 100
        element.value.should == '100'
      end

      it 'fires the keydown event' do
        @session.find(:css, '#changes_on_keydown').text.should == "6"
      end

      it 'fires the keyup event' do
        @session.find(:css, '#changes_on_keyup').text.should == "6"
      end

      it 'fires the keypress event' do
        @session.find(:css, '#changes_on_keypress').text.should == "6"
      end

      it 'fires the focus event' do
        @session.find(:css, '#changes_on_focus').text.should == "Focus"
      end

      it 'fires the blur event' do
        @session.find(:css, '#changes_on_blur').text.should == "Blur"
      end

      it "fires the keydown event before the value is updated" do
        @session.find(:css, '#value_on_keydown').text.should == "Hello"
      end

      it "fires the keyup event after the value is updated" do
        @session.find(:css, '#value_on_keyup').text.should == "Hello!"
      end

      it "clears the input before setting the new value" do
        element = @session.find(:css, '#change_me')
        element.set ""
        element.value.should == ""
      end

      it "supports special characters" do
        element = @session.find(:css, "#change_me")
        element.set "$52.00"
        element.value.should == "$52.00"
      end

      it 'attaches a file when passed a Pathname' do
        filename = Pathname.new('spec/tmp/a_test_pathname').expand_path
        File.open(filename, 'w') { |f| f.write('text') }

        element = @session.find(:css, '#change_me_file')
        element.set(filename)
        element.value.should == 'C:\fakepath\a_test_pathname'
      end
    end

    it 'has no trouble clicking elements when the size of a document changes' do
      @session.visit('/poltergeist/long_page')
      @session.find(:css, '#penultimate').click
      @session.execute_script <<-JS
        el = document.getElementById('penultimate')
        el.parentNode.removeChild(el)
      JS
      @session.click_link('Phasellus blandit velit')
      @session.should have_content("Hello")
    end

    it 'handles clicks where the target is in view, but the document is smaller than the viewport' do
      @session.visit '/poltergeist/simple'
      @session.click_link 'Link'
      @session.should have_content('Hello world')
    end

    it 'handles clicks where a parent element has a border' do
      @session.visit '/poltergeist/table'
      @session.click_link 'Link'
      @session.should have_content('Hello world')
    end

    it 'handles window.confirm(), returning true unconditionally' do
      @session.visit '/'
      @session.evaluate_script("window.confirm('foo')").should == true
    end

    it 'handles window.prompt(), returning the default value or null' do
      @session.visit '/'
      @session.evaluate_script("window.prompt()").should == nil
      @session.evaluate_script("window.prompt('foo', 'default')").should == 'default'
    end

    it 'handles evaluate_script values properly' do
      @session.evaluate_script('null').should == nil
      @session.evaluate_script('false').should == false
      @session.evaluate_script('true').should == true
      @session.evaluate_script("{foo: 'bar'}").should == {"foo" => "bar"}
    end

    it "synchronises page loads properly" do
      @session.visit '/poltergeist/index'
      @session.click_link "JS redirect"
      sleep 0.1
      @session.html.should include("Hello world")
    end

    context 'click tests' do
      before do
        @session.visit '/poltergeist/click_test'
      end

      after do
        @session.driver.resize(1024, 768)
      end

      it 'scrolls around so that elements can be clicked' do
        @session.driver.resize(200, 200)
        log = @session.find(:css, '#log')

        instructions = %w(one four one two three)
        instructions.each do |instruction, i|
          @session.find(:css, "##{instruction}").click
          log.text.should == instruction
        end
      end

      # See https://github.com/jonleighton/poltergeist/issues/60
      it "fixes some weird layout issue that we're not entirely sure about the reason for" do
        @session.visit '/poltergeist/datepicker'
        @session.find(:css, '#datepicker').set('2012-05-11')
        @session.click_link 'some link'
      end

      context 'with #two overlapping #one' do
        before do
          @session.execute_script <<-JS
            var two = document.getElementById('two')
            two.style.position = 'absolute'
            two.style.left     = '0px'
            two.style.top      = '0px'
          JS
        end

        it 'detects if an element is obscured when clicking' do
          expect {
            @session.find(:css, '#one').click
          }.to raise_error(Capybara::Poltergeist::MouseEventFailed)

          begin
            @session.find(:css, '#one').click
          rescue => error
            error.selector.should == "html body div#two.box"
            error.message.should include('[200, 200]')
          end
        end

        it 'clicks in the centre of an element' do
          begin
            @session.find(:css, '#one').click
          rescue => error
            error.position.should == [200, 200]
          end
        end

        it 'clicks in the centre of an element within the viewport, if part is outside the viewport' do
          @session.driver.resize(200, 200)

          begin
            @session.find(:css, '#one').click
          rescue => error
            error.position.first.should == 150
          end
        end
      end

      it "can evaluate a statement ending with a semicolon" do
        @session.evaluate_script("3;").should == 3
      end
    end

    context 'double click tests' do
      before do
        @session.visit '/poltergeist/double_click_test'
      end
      
      it 'double clicks properly' do
        @session.driver.resize(200, 200)
        log = @session.find(:css, '#log')

        instructions = %w(one four one two three)
        instructions.each do |instruction, i|
          @session.find(:css, "##{instruction}").base.double_click
          log.text.should == instruction
        end
      end
    end
    
    context 'status code support', :status_code_support => true do
      it 'should determine status code when an user goes to a page by using a link on it' do
        @session.visit '/poltergeist/with_different_resources'

        @session.click_link 'Go to 500'

        @session.status_code.should == 500
      end

      it 'should determine properly status code when an user goes through a few pages' do
        @session.visit '/poltergeist/with_different_resources'

        @session.click_link 'Go to 201'
        @session.click_link 'Do redirect'
        @session.click_link 'Go to 402'

        @session.status_code.should == 402
      end
    end

    it 'ignores cyclic structure errors in evaluate_script' do
      code = <<-CODE
        (function() {
          var a = {}
          a.a = a
          return a
        })()
      CODE
      @session.evaluate_script(code).should == "(cyclic structure)"
    end

    it 'returns BR as a space in #text' do
      @session.visit '/poltergeist/simple'
      @session.find(:css, '#break').text.should == "Foo Bar"
    end

    it 'handles hash changes' do
      @session.visit '/#omg'
      @session.current_url.should =~ /\/#omg$/
      @session.execute_script <<-CODE
        window.onhashchange = function() { window.last_hashchange = window.location.hash }
      CODE
      @session.visit '/#foo'
      @session.current_url.should =~ /\/#foo$/
      @session.evaluate_script("window.last_hashchange").should == '#foo'
    end

    context 'window switching support' do
      it 'waits for the window to load' do
        @session.visit '/'

        # setTimeout is necessary due to https://code.google.com/p/phantomjs/issues/detail?id=815
        @session.evaluate_script <<-CODE
          setTimeout(function() {
            window.open('/poltergeist/slow', 'popup')
          }, 0)
        CODE

        @session.within_window 'popup' do
          @session.html.should include('slow page')
          @session.evaluate_script('window.close()')
        end
      end

      it 'can access a second window of the same name' do
        @session.visit '/'

        @session.evaluate_script <<-CODE
          setTimeout(function() {
            window.open('/poltergeist/simple', 'popup')
          }, 0)
        CODE

        @session.within_window 'popup' do
          @session.html.should include('Test')
          @session.evaluate_script('window.close()')
        end

        @session.evaluate_script <<-CODE
          setTimeout(function() {
            window.open('/poltergeist/simple', 'popup')
          }, 0)
        CODE

        @session.within_window 'popup' do
          @session.html.should include('Test')
        end
      end
    end

    context 'frame support' do
      it 'waits for the frame to load' do
        @session.visit '/'

        @session.evaluate_script <<-CODE
          setTimeout(function() {
            document.body.innerHTML += '<iframe src="/poltergeist/slow" name="frame">'
          }, 0)
        CODE

        @session.within_frame 'frame' do
          @session.current_path.should == "/poltergeist/slow"
          @session.html.should include('slow page')
        end

        @session.current_path.should == '/'
      end

      it 'waits for the cross-domain frame to load' do
        @session.visit '/poltergeist/frames'
        @session.current_path.should == '/poltergeist/frames'

        @session.within_frame 'frame' do
          @session.current_path.should == '/poltergeist/slow'
          @session.body.should include('slow page')
        end

        @session.current_path.should == '/poltergeist/frames'
      end

      it 'supports clicking in a frame' do
        @session.visit '/'

        @session.evaluate_script <<-CODE
          setTimeout(function() {
            document.body.innerHTML += '<iframe src="/poltergeist/click_test" name="frame">'
          }, 0)
        CODE

        @session.within_frame 'frame' do
          log = @session.find(:css, '#log')
          @session.find(:css, "#one").click
          log.text.should == "one"
        end
      end

      it "doesn't wait forever for the frame to load" do
        @session.visit '/'

        expect {
          @session.within_frame('omg') { }
        }.to raise_error(Capybara::Poltergeist::FrameNotFound)
      end
    end

    # see https://github.com/jonleighton/poltergeist/issues/115
    it "handles obsolete node during an attach_file" do
      @session.visit "/poltergeist/attach_file"
      @session.attach_file "file", __FILE__
    end

    it "logs mouse event co-ordinates" do
      @session.visit("/")
      @session.find(:css, "a").click

      position = eval(TestSessions.logger.messages.last)["response"]["position"]
      position["x"].should_not be_nil
      position["y"].should_not be_nil
    end

    it "throws an error on an invalid selector" do
      @session.visit "/poltergeist/table"
      expect { @session.find(:css, "table tr:last") }.to raise_error(Capybara::Poltergeist::InvalidSelector)
    end
  end
end
