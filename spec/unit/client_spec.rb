require 'spec_helper'

module Capybara::Poltergeist
  describe Client do
    let(:server) { double(port: 6000) }
    let(:client_params) { {} }
    subject { Client.new(server, client_params) }

    context '#initialize' do
      it 'raises an error if phantomjs is too old' do
        Cliver::Detector.any_instance.
          stub(:`).with(/phantomjs --version/).and_return("1.3.0\n")
        expect { subject }.to raise_error(Cliver::Dependency::VersionMismatch)
      end

      it "doesn't raise an error if phantomjs is too new" do
        Cliver::Detector.any_instance.
          stub(:`).with(/phantomjs --version/).and_return("1.10.0 (development)\n")
        expect { subject }.not_to raise_error
        subject.stop # process has been spawned, stopping
      end

      it 'shows the detected version in the version error message' do
        Cliver::Detector.any_instance.
          stub(:`).with(/phantomjs --version/).and_return("1.3.0\n")
        expect { subject }.to raise_error(Cliver::Dependency::VersionMismatch) do |e|
          e.message.should include('1.3.0')
        end
      end

      context 'when phantomjs does not exist' do
        let(:client_params) { { :path => '/does/not/exist' } }
        it 'raises an error' do
          expect { subject }.to raise_error(Cliver::Dependency::NotFound)
        end
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
