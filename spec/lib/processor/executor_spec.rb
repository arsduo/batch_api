require 'spec_helper'
require 'batch_api/processor/executor'

describe BatchApi::Processor::Executor do

  let(:app) { double("app", call: double) }
  let(:executor) { BatchApi::Processor::Executor.new(app) }
  let(:result) { double("result") }
  let(:op) { double("operation", execute: result) }
  let(:env) { {op: op} }

  describe "#call" do
    it "executes the operation" do
      expect(op).to receive(:execute)
      executor.call(env)
    end

    it "returns the result" do
      expect(executor.call(env)).to eq(result)
    end
  end
end
