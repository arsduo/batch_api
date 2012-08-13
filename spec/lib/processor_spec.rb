require 'spec_helper'

describe BatchApi::Processor do
  it "provides a OperationLimitExceeded error" do
    BatchApi::Processor::OperationLimitExceeded.superclass.should == StandardError
  end

  it "provides a OperationLimitExceeded error" do
    BatchApi::Processor::BadOptionError.superclass.should == StandardError
  end

  let(:ops) { [ {url: "/endpoint", method: "get"} ] }
  let(:options) { { sequential: true } }
  let(:env) { {} }
  let(:processor) { BatchApi::Processor.new(ops, env, options) }

  describe "#initialize" do
    # this may be brittle...consider refactoring?
    it "turns the ops provided into BatchApi::Operations stored at #ops" do
      # simulate receiving several operations
      operation_objects = 3.times.collect { stub("operation object") }
      operation_params = 3.times.collect do |i|
        stub("raw operation").tap do |o|
          BatchApi::Operation.should_receive(:new).with(o, anything).and_return(operation_objects[i])
        end
      end

      BatchApi::Processor.new(operation_params, env, options).ops.should == operation_objects
    end

    it "makes the options available" do
      BatchApi::Processor.new(ops, env, options).options.should == options
    end

    context "error conditions" do
      it "(currently) throws an error if sequential is not true" do
        expect { BatchApi::Processor.new(ops, env, {}) }.to raise_exception(BatchApi::Processor::BadOptionError)
      end

      it "raise a OperationLimitExceeded error if too many ops provided" do
        ops = (BatchApi.config.limit + 1).times.collect {|i| i}
        expect { BatchApi::Processor.new(ops, env, options) }.to raise_exception(BatchApi::Processor::OperationLimitExceeded)
      end
    end

    describe "#strategy" do
      it "returns BatchApi::Processor::Strategies::Sequential" do
        processor.strategy.should == BatchApi::Processor::Strategies::Sequential
      end
    end

    describe "#execute!" do
      it "executes on the provided strategy" do
        processor.strategy.should_receive(:execute!).with(processor.ops, processor.options)
        processor.execute!
      end

      it "returns the result of the strategy" do
        stubby = stub
        processor.strategy.stub(:execute!).and_return(stubby)
        processor.execute!.should == stubby
      end
    end
  end
end
