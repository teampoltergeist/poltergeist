require 'spec_helper'

module Capybara::Poltergeist
  describe Client do
    let(:server) { double(port: 6000) }
    let(:client_params) { {} }
    subject { Client.new(server, client_params) }

    context '#initialize' do
      it 'raises an error if phantomjs is too old' do
        stub_version('1.3.0')
        expect { subject }.to raise_error(Cliver::Dependency::VersionMismatch)
      end

      it "doesn't raise an error if phantomjs is too new" do
        begin
          stub_version('1.10.0 (development)')
          expect { subject }.to_not raise_error
        ensure
          subject.stop # process has been spawned, stopping
        end
      end

      it 'shows the detected version in the version error message' do
        stub_version('1.3.0')
        expect { subject }.to raise_error(Cliver::Dependency::VersionMismatch) do |e|
          expect(e.message).to include('1.3.0')
        end
      end

      context 'when phantomjs does not exist' do
        let(:client_params) { { path: '/does/not/exist' } }

        it 'raises an error' do
          expect { subject }.to raise_error(Cliver::Dependency::NotFound)
        end
      end

      def stub_version(version)
        Cliver::ShellCapture.any_instance.stub(
          stdout: "#{version}\n",
          command_found: true
        )
      end
    end

    unless Capybara::Poltergeist.windows?
      it "forcibly kills the child if it doesn't respond to SIGTERM" do
        client = Client.new(server)

        Process.stub(spawn: 5678)
        Process.stub(:wait) do
          @count = @count.to_i + 1
          @count == 1 ? sleep(3) : 0
        end

        client.start

        Process.should_receive(:kill).with('TERM', 5678).ordered
        Process.should_receive(:kill).with('KILL', 5678).ordered

        client.stop
      end
    end
  end
end
