require 'spec_helper'
require 'capybara/spec/session'

describe Capybara::Session do
  context 'with poltergeist driver' do
    # This seems to prevent some segfaulting of PhantomJS when the tests are run all together :( :(
    before(:all) do
      TestSessions::Poltergeist.driver.restart
    end

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
    end

    describe 'Node#set' do
      it 'should fire the change event' do
        @session.visit('/poltergeist/with_js')
        @session.find(:css, '#change_me').set("Hello!")
        @session.find(:css, '#changes').text.should == "Hello!"
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
        (function() {
          el = document.getElementById('penultimate')
          el.parentNode.removeChild(el)
        })()
      JS
      @session.click_link('Phasellus blandit velit')
      @session.should have_content("Hello")
    end
  end
end
