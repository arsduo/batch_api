require 'batch_api/errors/request'

describe BatchApi::Errors::Request do

  it "subclasses the base" do
    BatchApi::Errors::Request.superclass.should == BatchApi::Errors::Base
  end

  describe "status code" do
    include
    [
      BatchApi::Processor::BadOptionError,
      BatchApi::Processor::OperationLimitExceeded,
      BatchApi::Processor::NoOperationsError,
      BatchApi::Operation::MalformedOperationError
    ].each do |e|
      err = e
      it "returns a 422 for #{err}" do
        BatchApi::Errors::Request.new(err.new).status_code.should == 422
      end
    end

    it "returns a 500 otherwise" do
      BatchApi::Errors::Request.new(RuntimeError.new).status_code.should == 500
    end
  end
end
