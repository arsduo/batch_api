require 'batch_api/config'

describe BatchAPI::Config do
  let(:config) { BatchAPI::Config.new }

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
  end
end
