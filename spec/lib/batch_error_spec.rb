require 'spec_helper'

describe BatchApi::Errors::BatchError do

  [
    BatchApi::Errors::OperationLimitExceeded,
    BatchApi::Errors::BadOptionError,
    BatchApi::Errors::NoOperationsError,
    BatchApi::Errors::MalformedOperationError
  ].each do |klass|
    it "provides a #{klass} error based on ArgumentError" do
      expect(klass.superclass).to eq(ArgumentError)
    end

    it "is is also a BatchError" do
      expect(klass.new).to be_a(BatchApi::Errors::BatchError)
    end

    it "has a status code of 422" do
      expect(klass.new.status_code).to eq(422)
    end
  end
end
