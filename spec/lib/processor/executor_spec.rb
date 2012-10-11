require 'spec_helper'
require 'batch_api/processor/executor'

describe BatchApi::Processor::Executor do

  let(:app) { stub("app", call: stub) }
  let(:executor) { BatchApi::Processor::Executor.new(app) }
  let(:result) { stub("result") }
  let(:op) { stub("operation", execute: result) }
  let(:env) { {op: op} }

  describe "#call" do
    it "executes the operation" do
      op.should_receive(:execute)
      executor.call(env)
    end

    it "returns the result" do
      executor.call(env).should == result
    end
  end
end
