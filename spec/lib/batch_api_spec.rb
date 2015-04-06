require 'spec_helper'
require 'batch_api'

describe BatchApi do
  describe ".config" do
    it "has a reader for config" do
      expect(BatchApi.config).not_to be_nil
    end

    it "provides a default config" do
      expect(BatchApi.config).to be_a(BatchApi::Configuration)
    end
  end

  describe ".rails?" do
    it "returns a value we can't test based on whether Rails is defined" do
      expect(BatchApi.rails?).not_to be_nil
    end
  end
end
