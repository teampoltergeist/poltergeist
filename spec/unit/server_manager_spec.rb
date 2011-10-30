require 'spec_helper'

module Capybara::Poltergeist
  describe ServerManager do
    subject { ServerManager.instance }

    it 'should operate a timeout for waiting for a message' do
      Timeout.stub(:timeout).with(ServerManager.timeout).and_raise(Timeout::Error)
      lambda { subject.send(2000, 'omg') }.should raise_error(TimeoutError)
    end

    it 'should include the message that was sent in the timeout exception' do
      Timeout.stub(:timeout).with(ServerManager.timeout).and_raise(Timeout::Error)
      begin
        subject.send(2000, 'omg')
      rescue TimeoutError => e
        e.message.should include('omg')
      end
    end
  end
end
