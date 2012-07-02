require 'spec_helper'

module Capybara::Poltergeist
  describe Client do
    subject { Client.new(6000) }

    it 'raises an error if phantomjs is too old' do
      `true` # stubbing $?
      subject.stub(:`).with('phantomjs --version').and_return("1.3.0\n")
      expect { subject.start }.to raise_error(PhantomJSTooOld)
    end

    it 'shows the detected version in the version error message' do
      `true` # stubbing $?
      subject.stub(:`).with('phantomjs --version').and_return("1.3.0\n")
      begin
        subject.start
      rescue PhantomJSTooOld => e
        e.message.should include('1.3.0')
      end
    end

    it 'raises an error if phantomjs returns a non-zero exit code' do
      subject = Client.new(6000, nil, 'exit 42 && ')
      expect { subject.start }.to raise_error(Error)

      begin
        subject.start
      rescue PhantomJSFailed => e
        e.message.should include('42')
      end
    end

    context "with width and height specified" do
      subject { Client.new(6000, nil, nil, 800, 600) }

      it "starts phantomjs, passing the width and height through" do
        Spawn.should_receive(:spawn).with("phantomjs", Client::PHANTOMJS_SCRIPT, 6000, 800, 600)
        subject.start
      end
    end

    context "when ssl error ignorance is specified" do
      subject { Client.new(6000, nil, nil, nil, nil, true) }

      it "starts phantomjs, passing the ignore ssl errors parameter through" do
        Spawn.should_receive(:spawn).with("phantomjs", "--ignore-ssl-errors=yes", Client::PHANTOMJS_SCRIPT, 6000, nil, nil)
        subject.start
      end
    end
  end
end
