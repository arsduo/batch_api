require 'spec_helper'

describe BatchApi::Processor::Sequential do

  let(:app) { double("app", call: double) }
  let(:sequential) { BatchApi::Processor::Sequential.new(app) }

  describe "#call" do
    let(:call_results) { 3.times.collect {|i| double("called #{i}") } }
    let(:env) { {
      ops: 3.times.collect {|i| double("op #{i}") }
    } }
    let(:op_middleware) { double("middleware", call: {}) }

    before :each do
      allow(BatchApi::InternalMiddleware).
        to receive(:operation_stack).and_return(op_middleware)
      allow(op_middleware).to receive(:call).and_return(*call_results)
    end

    it "creates an operation middleware stack and calls it for each op" do
      env[:ops].each {|op|
        expect(op_middleware).to receive(:call).
          with(hash_including(op: op)).ordered
      }
      sequential.call(env)
    end

    it "includes the rest of the env in the calls" do
      expect(op_middleware).to receive(:call).
        with(hash_including(env)).exactly(3).times
      sequential.call(env)
    end

    it "returns the results of the calls" do
      expect(sequential.call(env)).to eq(call_results)
    end
  end
end
