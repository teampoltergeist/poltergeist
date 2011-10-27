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
    path = '/tmp/poltergeist_phantomjs'

    begin
      FileUtils.rm_f(path)
      File.symlink(`which phantomjs`.chomp, path)
      File.chmod(0755, path)

      driver  = Capybara::Poltergeist::Driver.new(nil, :phantomjs => path)
      driver.browser

      `ps -C poltergeist_phantomjs -o command=`.should include(path)
    ensure
      FileUtils.rm(path)
    end
  end
end
