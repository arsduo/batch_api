require 'spec_helper'

describe BatchApi::Configuration do
  let(:config) { BatchApi::Configuration.new }

  describe "options" do
    describe "#verb" do
      it "has an accessor for verb" do
        stubby = stub
        config.verb = stubby
        config.verb.should == stubby
      end

      it "defaults verb to :post" do
        config.verb.should == :post
      end
    end

    describe "#endpoint" do
      it "has an accessor for endpoint" do
        stubby = stub
        config.endpoint = stubby
        config.endpoint.should == stubby
      end

      it "defaults verb to /batch" do
        config.endpoint.should == "/batch"
      end
    end

    describe "#limit" do
      it "has an accessor for limit" do
        stubby = stub
        config.limit= stubby
        config.limit.should == stubby
      end

      it "defaults verb to /batch" do
        config.limit.should == 20
      end
    end
  end
end


