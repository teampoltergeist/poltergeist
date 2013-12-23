require 'spec_helper'
require 'stringio'

module Capybara::Poltergeist
  describe Browser do
    let(:server) { double("server").as_null_object }
    let(:client) { double("client").as_null_object }

    context 'with a logger' do
      let(:logger) { StringIO.new }
      subject      { Browser.new(server, client, logger) }

      it 'logs requests and responses to the client' do
        request = %({"name":"where is","args":["the love?"]})
        response = %({"response":"<3"})
        server.stub(:send).with(request).and_return(response)

        subject.command('where is', 'the love?')

        expect(logger.string).to eq("#{request}\n#{response}\n")
      end
    end
  end
end
