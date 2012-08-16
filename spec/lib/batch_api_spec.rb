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
end
