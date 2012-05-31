require 'spec_helper'
require 'capybara/spec/session'

describe Capybara::Session do
  context 'with poltergeist driver' do
    before do
      @session = TestSessions::Poltergeist
    end

    it_should_behave_like "session"
    it_should_behave_like "session with javascript support"
    it_should_behave_like "session without headers support"
    it_should_behave_like "session without status code support"

    describe Capybara::Poltergeist::Node do
      it 'should raise an error if the element has been removed from the DOM' do
        @session.visit('/poltergeist/with_js')
        node = @session.find(:css, '#remove_me')
        node.text.should == 'Remove me'
        @session.find(:css, '#remove').click
        lambda { node.text }.should raise_error(Capybara::Poltergeist::ObsoleteNode)
      end

      it 'should raise an error if the element was on a previous page' do
        @session.visit('/poltergeist/index')
        node = @session.find('.//a')
        @session.execute_script "window.location = 'about:blank'"
        expect { node.text }.to raise_error(Capybara::Poltergeist::ObsoleteNode)
      end
    end

    describe 'Node#set' do
      before do
        @session.visit('/poltergeist/with_js')
        @session.find(:css, '#change_me').set("Hello!")
      end

      it 'should fire the change event' do
        @session.find(:css, '#changes').text.should == "Hello!"
      end

      it 'should accept numbers in a maxlength field' do
        element = @session.find(:css, '#change_me_maxlength')
        element.set 100
        element.value.should == '100'
      end

      it 'should fire the keydown event' do
        @session.find(:css, '#changes_on_keydown').text.should == "6"
      end

      it 'should fire the keyup event' do
        @session.find(:css, '#changes_on_keyup').text.should == "6"
      end

      it 'should fire the keypress event' do
        @session.find(:css, '#changes_on_keypress').text.should == "6"
      end

      it 'should fire the focus event' do
        @session.find(:css, '#changes_on_focus').text.should == "Focus"
      end

      it 'should fire the blur event' do
        @session.find(:css, '#changes_on_blur').text.should == "Blur"
      end
    end

    it 'should support running multiple sessions at once' do
      other_session = Capybara::Session.new(:poltergeist, TestApp)

      @session.visit('/')
      other_session.visit('/')

      @session.should have_content("Hello")
      other_session.should have_content("Hello")
    end

    it 'should not have trouble clicking elements when the size of a document changes' do
      @session.visit('/poltergeist/long_page')
      @session.find(:css, '#penultimate').click
      @session.execute_script <<-JS
        el = document.getElementById('penultimate')
        el.parentNode.removeChild(el)
      JS
      @session.click_link('Phasellus blandit velit')
      @session.should have_content("Hello")
    end

    it 'should handle clicks where the target is in view, but the document is smaller than the viewport' do
      @session.visit '/poltergeist/simple'
      @session.click_link 'Link'
      @session.should have_content('Hello world')
    end

    it 'should handle clicks where a parent element has a border' do
      @session.visit '/poltergeist/table'
      @session.click_link 'Link'
      @session.should have_content('Hello world')
    end

    it 'should handle window.confirm(), returning true unconditionally' do
      @session.visit '/'
      @session.evaluate_script("window.confirm('foo')").should == true
    end

    it 'should handle window.prompt(), returning the default value or null' do
      @session.visit '/'
      @session.evaluate_script("window.prompt()").should == nil
      @session.evaluate_script("window.prompt('foo', 'default')").should == 'default'
    end

    it 'should handle evaluate_script values properly' do
      @session.evaluate_script('null').should == nil
      @session.evaluate_script('false').should == false
      @session.evaluate_script('true').should == true
      @session.evaluate_script("{foo: 'bar'}").should == {"foo" => "bar"}
    end

    it "synchronises page loads properly" do
      @session.visit '/poltergeist/index'
      @session.click_link "JS redirect"
      sleep 0.1
      @session.body.should include("Hello world")
    end

    context 'click tests' do
      before do
        @session.visit '/poltergeist/click_test'
      end

      after do
        @session.driver.resize(1024, 768)
      end

      it 'should scroll around so that elements can be clicked' do
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
          }.to raise_error(Capybara::Poltergeist::ClickFailed)

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
            error.position.should == [150, 150]
          end
        end
      end
    end
  end
end
