require 'spec_helper'

module Capybara::Poltergeist
  describe Driver do
    context 'with no options' do
      subject { Driver.new(nil) }

      it 'should not log' do
        subject.logger.should == nil
      end
    end

    context 'with a :logger option' do
      subject { Driver.new(nil, :logger => :my_custom_logger) }

      it 'should log to the logger given' do
        subject.logger.should == :my_custom_logger
      end
    end

    context 'with a :debug => true option' do
      subject { Driver.new(nil, :debug => true) }

      it 'should log to STDERR' do
        subject.logger.should == STDERR
      end
    end
  end
end
