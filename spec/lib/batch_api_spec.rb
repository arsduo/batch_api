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

  describe ".rails?" do
    it "returns a value we can't test based on whether Rails is defined" do
      BatchApi.rails?.should_not be_nil
    end
  end
end
