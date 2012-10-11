require 'spec_helper'

describe BatchApi::Errors::BatchError do

  [
    BatchApi::Errors::OperationLimitExceeded,
    BatchApi::Errors::BadOptionError,
    BatchApi::Errors::NoOperationsError,
    BatchApi::Errors::MalformedOperationError
  ].each do |klass|
    it "provides a #{klass} error based on ArgumentError" do
      klass.superclass.should == ArgumentError
    end

    it "is is also a BatchError" do
      klass.new.should be_a(BatchApi::Errors::BatchError)
    end

    it "has a status code of 422" do
      klass.new.status_code.should == 422
    end
  end
end
