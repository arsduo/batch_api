require 'spec_helper'
require 'batch_api'

describe BatchApi do
  describe ".setup" do
    it "has an accessor for config" do
      stubby = stub
      BatchApi.config = stubby
      BatchApi.config.should == stubby
    end

    it "yields a new config object" do
      BatchApi.setup do |c|
        c.should be_a(BatchApi::Configuration)
      end
    end

    it "stores the config object" do
      expected = nil
      BatchApi.setup {|c| expected = c}
      BatchApi.config.should == expected
    end
  end
end
