require 'spec_helper'
require 'capybara/spec/driver'

describe Capybara::Poltergeist::Driver do
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
end
