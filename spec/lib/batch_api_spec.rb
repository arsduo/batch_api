require 'spec_helper'
require 'batch_api'

describe BatchApi do
  describe ".config" do
    it "has a reader for config" do
      BatchApi.config.should_not be_nil
    end

    it "provides a default config" do
      BatchApi.config.should be_a(BatchApi::Configuration)
    end
  end

  describe ".setup" do
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
