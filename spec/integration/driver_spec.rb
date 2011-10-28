require 'spec_helper'

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
    path = File.expand_path('../../support/custom_phantomjs', __FILE__)

    driver  = Capybara::Poltergeist::Driver.new(nil, :phantomjs => path)
    driver.browser

    `ps -o command=`.should include(path)
  end
end
