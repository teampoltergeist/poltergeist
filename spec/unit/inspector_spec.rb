require 'spec_helper'

module Capybara::Poltergeist
  describe Inspector do
    it 'detects a browser by default' do
      allow(Inspector).to receive_messages(detect_browser: 'chromium')
      expect(Inspector.new.browser).to eq('chromium')
      expect(Inspector.new(true).browser).to eq('chromium')
    end

    it 'allows a browser to be specified' do
      expect(Inspector.new('foo').browser).to eq('foo')
    end

    it 'has a url' do
      subject = Inspector.new(nil, 1234)
      expect(subject.url).to eq('//localhost:1234/')
    end

    it 'can be opened' do
      subject = Inspector.new('chromium', 1234)
      expect(Process).to receive(:spawn).with('chromium', '//localhost:1234/')
      subject.open
    end

    it 'raises an error on open when the browser is unknown' do
      subject = Inspector.new(nil, 1234)
      allow(subject).to receive_messages(browser: nil)

      expect { subject.open }.to raise_error(Capybara::Poltergeist::Error)
    end
  end
end
