require 'spec_helper'

describe BatchApi::Processor do
  it "provides a OperationLimitExceeded error" do
    BatchApi::Processor::OperationLimitExceeded.superclass.should == StandardError
  end

  it "provides a OperationLimitExceeded error" do
    BatchApi::Processor::BadOptionError.superclass.should == StandardError
  end

  let(:ops) { [ {url: "/endpoint", method: "get"} ] }
  let(:options) { { "sequential" => true } }
  let(:env) { {
    "action_dispatch.request.request_parameters" => {}.merge("ops" => ops).merge(options)
  } }
  let(:app) { stub("application", call: [200, {}, ["foo"]]) }
  let(:processor) { BatchApi::Processor.new(env, app) }

  describe "#initialize" do
    # this may be brittle...consider refactoring?
    it "turns the ops provided into BatchApi::Operations stored at #ops" do
      # simulate receiving several operations
      operation_objects = 3.times.collect { stub("operation object") }
      operation_params = 3.times.collect do |i|
        stub("raw operation").tap do |o|
          BatchApi::Operation.should_receive(:new).with(o, env, app).and_return(operation_objects[i])
        end
      end

      env["action_dispatch.request.request_parameters"]["ops"] = operation_params
      BatchApi::Processor.new(env, app).ops.should == operation_objects
    end

    it "makes the options available" do
      BatchApi::Processor.new(env, app).options.should == options
    end

    context "error conditions" do
      it "(currently) throws an error if sequential is not true" do
        env["action_dispatch.request.request_parameters"].delete("sequential")
        expect { BatchApi::Processor.new(env, app) }.to raise_exception(BatchApi::Processor::BadOptionError)
      end

      it "raise a OperationLimitExceeded error if too many ops provided" do
        ops = (BatchApi.config.limit + 1).times.collect {|i| i}
        env["action_dispatch.request.request_parameters"]["ops"] = ops
        expect { BatchApi::Processor.new(env, app) }.to raise_exception(BatchApi::Processor::OperationLimitExceeded)
      end

      it "raises an ArgumentError if operations.blank?" do
        env["action_dispatch.request.request_parameters"]["ops"] = nil
        expect { BatchApi::Processor.new(env, app) }.to raise_exception(ArgumentError)
        env["action_dispatch.request.request_parameters"]["ops"] = []
        expect { BatchApi::Processor.new(env, app) }.to raise_exception(ArgumentError)
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
