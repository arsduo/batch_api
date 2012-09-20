require 'spec_helper'
require 'batch_api/processor/executor'

describe BatchApi::Processor::Executor do

  let(:app) { stub("app", call: stub) }
  let(:executor) { BatchApi::Processor::Executor.new(app) }
  let(:rack) { stub("rack array") }
  let(:result) { stub("result", to_rack: rack) }
  let(:op) { stub("operation", execute: result) }
  let(:env) { {op: op} }

  describe "#call" do
    it "executes the operation" do
      op.should_receive(:execute)
      executor.call(env)
    end

    it "returns the result as a Rack array" do
      executor.call(env).should == result.to_rack
    end
  end
end
