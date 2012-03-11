require 'spec_helper'

module Capybara::Poltergeist
  describe Inspector do
    it 'detects a browser by default' do
      Inspector.stub(:detect_browser => 'chromium')
      Inspector.new.browser.should == 'chromium'
      Inspector.new(true).browser.should == 'chromium'
    end

    it 'allows a browser to be specified' do
      Inspector.new('foo').browser.should == 'foo'
    end

    it 'finds a port to run on' do
      subject.port.should_not be_nil
    end

    it 'remembers the port' do
      subject.port.should == subject.port
    end

    it 'has a url' do
      subject.stub(:port => 1234)
      subject.url.should == "http://localhost:1234/"
    end

    it 'can be opened' do
      subject.stub(:port => 1234, :browser => 'chromium')
      Spawn.should_receive(:spawn).with("chromium", "http://localhost:1234/")
      subject.open
    end

    it 'raises an error on open when the browser is unknown' do
      subject.stub(:port => 1234, :browser => nil)
      expect { subject.open }.to raise_error(Capybara::Poltergeist::Error)
    end
  end
end
