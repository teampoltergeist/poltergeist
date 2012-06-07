require 'spec_helper'
require 'multi_json'

module Capybara::Poltergeist
  describe NetworkTraffic do

    before(:all) do
      dir = File.dirname(__FILE__) + "/../support"
      json = File.read("#{dir}/network_traffic.json")
      @hash = MultiJson.load(json)
      @traffic = NetworkTraffic.new(@hash)
    end

    it "converts network traffic hash into internal request and response objects" do
      @traffic.request.url.should match(/test\.js$/)
      @traffic.response.status.should == 200
    end

    it "underscorizes the property names" do
      @traffic.response.status_text.should match(/OK/)
    end

    it "sets body size on the response for the startReply object" do
      @traffic.response.body_size.should == 707
    end

    it "has a url method that returns the url from the response" do
      @traffic.url.should match(/test\.js$/)
    end

    it "parses the time into Time objects" do
      @traffic.request.time.should be_a(Time)
      @traffic.response.time.should be_a(Time)
      @traffic.request.time.year.should == 2012
      @traffic.response.time.year.should == 2012
      @traffic.request.time.should < @traffic.response.time
    end

  end
end
