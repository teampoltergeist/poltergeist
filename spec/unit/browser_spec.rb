require 'spec_helper'
require 'stringio'

module Capybara::Poltergeist
  describe Browser do
    let(:server) { double("server").as_null_object }
    let(:client) { double("client").as_null_object }

    before do
      Server.stub(:new).and_return(server)
      Client.stub(:new).and_return(client)
    end

    context 'with a logger' do
      let(:logger) { StringIO.new }
      subject      { Browser.new(:logger => logger) }

      it 'should log requests and responses to the client' do
        request  = { 'name' => 'where is', 'args' => ["the love?"] }
        response = { 'response' => '<3' }
        server.stub(:send).with(JSON.generate(request)).and_return(JSON.generate(response))

        subject.command('where is', 'the love?')

        logger.string.should == "#{request.inspect}\n#{response.inspect}\n"
      end
    end
  end
end
