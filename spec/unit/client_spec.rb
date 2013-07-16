require 'spec_helper'

module Capybara::Poltergeist
  describe Client do
    let(:server) { double(port: 6000) }

    subject { Client.new(server) }

    it 'raises an error if phantomjs is too old' do
      `true` # stubbing $?
      subject.stub(:`).with('phantomjs --version').and_return("1.3.0\n")
      expect { subject.start }.to raise_error(PhantomJSTooOld)
    end

    it "doesn't raise an error if phantomjs is too new" do
      `true` # stubbing $?
      subject.stub(:`).with('phantomjs --version').and_return("1.10.0 (development)\n")
      expect { subject.start }.not_to raise_error
      subject.stop # process has been spawned, stopping
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
      subject = Client.new(server, :path => 'exit 42 && ')
      expect { subject.start }.to raise_error(Error)

      begin
        subject.start
      rescue PhantomJSFailed => e
        e.message.should include('42')
      end
    end

    unless Capybara::Poltergeist.windows?
      it "forcibly kills the child if it doesn't respond to SIGTERM" do
        begin
          class << Process
            alias old_wait wait
          end

          client = Client.new(server)
          Process.stub(spawn: 5678)
          client.start

          Process.should_receive(:kill).with('TERM', 5678).ordered

          count = 0
          Process.singleton_class.send(:define_method, :wait) do |*args|
            count += 1
            count == 1 ? sleep(3) : 0
          end

          Process.should_receive(:kill).with('KILL', 5678).ordered

          client.stop
        ensure
          class << Process
            undef wait
            alias wait old_wait
            undef old_wait
          end
        end
      end
    end
  end
end
