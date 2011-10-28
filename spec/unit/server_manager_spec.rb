require 'spec_helper'

module Capybara::Poltergeist
  describe ServerManager do
    subject { ServerManager.instance }

    it 'should operate a timeout for waiting for a message' do
      Timeout.should_receive(:timeout).with(ServerManager.timeout).and_raise(Timeout::Error)
      lambda { subject.send(2000, 'omg') }.should raise_error(ServerManager::TimeoutError)
    end
  end
end
