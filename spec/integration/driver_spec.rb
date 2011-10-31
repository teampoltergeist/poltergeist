require 'spec_helper'
require 'capybara/spec/driver'

module Capybara::Poltergeist
  describe Driver do
    before do
      @driver = TestSessions::Poltergeist.driver
    end

    it_should_behave_like "driver"
    it_should_behave_like "driver with javascript support"
    it_should_behave_like "driver with frame support"
    it_should_behave_like "driver without status code support"
    it_should_behave_like "driver with cookies support"

    it 'should support a custom phantomjs path' do
      file = File.expand_path('../../support/custom_phantomjs_called', __FILE__)
      path = File.expand_path('../../support/custom_phantomjs',        __FILE__)

      FileUtils.rm_f file

      driver  = Capybara::Poltergeist::Driver.new(nil, :phantomjs => path)
      driver.browser

      # If the correct custom path is called, it will touch the file. We allow at
      # least 1 sec for this to happen before failing.

      tries = 0
      until File.exist?(file) || tries == 10
        sleep 0.1
        tries += 1
      end

      File.exist?(file).should == true
    end

    it 'should raise an error and restart the client, if the client dies while executing a command' do
      lambda { @driver.browser.command('exit') }.should raise_error(DeadClient)
      @driver.visit('/')
      @driver.body.should include('Hello world')
    end

    it 'should have a viewport size of 1024x768 by default' do
      @driver.visit('/')
      @driver.evaluate_script('[window.innerWidth, window.innerHeight]').should == [1024, 768]
    end

    it 'should allow the viewport to be resized' do
      @driver.visit('/')
      @driver.resize(200, 400)
      @driver.evaluate_script('[window.innerWidth, window.innerHeight]').should == [200, 400]
    end
  end
end
