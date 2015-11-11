require 'spec_helper'
require 'stringio'

module Capybara::Poltergeist
  describe Browser do
    let(:server) { double('server').as_null_object }
    let(:client) { double('client').as_null_object }

    context 'with a logger' do
      let(:logger) { StringIO.new }
      subject      { Browser.new(server, client, logger) }

      it 'logs requests and responses to the client' do
        response = %({"response":"<3"})
        allow(server).to receive(:send).and_return(response)

        subject.command('where is', 'the love?')

        expect(logger.string).to include('"name":"where is","args":["the love?"]')
        expect(logger.string).to include("#{response}")
      end
    end
  end
end
