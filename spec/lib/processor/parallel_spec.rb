require 'spec_helper'

describe BatchApi::Processor::Parallel do

  let(:app) { stub("app", call: stub) }
  let(:parallel) { BatchApi::Processor::Parallel.new(app) }

  describe "#call" do
    let(:call_results) { 3.times.collect {|i| stub("called #{i}") } }
    let(:env) { {
        ops: 3.times.collect {|i| stub("op #{i}") }
    } }
    let(:op_middleware) { stub("middleware", call: {}) }

    before :each do
      BatchApi::InternalMiddleware.
          stub(:operation_stack).and_return(op_middleware)
      op_middleware.stub(:call).and_return(*call_results)
    end

    it "creates an operation middleware stack and calls it for each op" do
      env[:ops].each {|op|
        op_middleware.should_receive(:call).
            with(hash_including(op: op))
      }
      parallel.call(env)
    end

    it "includes the rest of the env in the calls" do
      op_middleware.should_receive(:call).
          with(hash_including(env)).exactly(3).times
      parallel.call(env)
    end

    it "returns the results of the calls" do
      parallel.call(env).should =~ call_results
    end
  end
end