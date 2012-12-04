require 'spec_helper'

class FakeOperationStack
  def call(env)
    "Called #{env[:op].method} #{env[:op].number}"
  end
end

describe BatchApi::Processor::Semiparallel do

  let(:app) { stub("app", call: stub) }
  let(:semiparallel) { BatchApi::Processor::Semiparallel.new(app) }

  describe "#call" do
    let(:env) { {
      ops: 10.times.collect {|i|
        meth = (3..6).to_a.include?(i) ? 'get' : 'post'
        stub("op #{i} #{meth}", method: meth, number: i)
      }
    } }
    let(:stack) { FakeOperationStack.new }

    before :each do
      BatchApi::InternalMiddleware.stub(:operation_stack).and_return(stack)
    end

    it "creates an operation middleware stack and calls it for each op" do
      env[:ops][0..2].each {|op|
        stack.should_receive(:call).
          with(hash_including(op: op)).ordered
      }

      env[:ops][3..6].each {|op|
        stack.should_receive(:call).
          with(hash_including(op: op))
      }

      env[:ops][7..9].each {|op|
        stack.should_receive(:call).
          with(hash_including(op: op)).ordered
      }

      semiparallel.call(env)
    end

    it "includes the rest of the env in the calls" do
      stack.should_receive(:call).
        with(hash_including(env)).exactly(10).times
      semiparallel.call(env)
    end

    it "returns the results of the calls ordered" do
      semiparallel.call(env).should == [
        "Called post 0",
        "Called post 1",
        "Called post 2",
        "Called get 3",
        "Called get 4",
        "Called get 5",
        "Called get 6",
        "Called post 7",
        "Called post 8",
        "Called post 9"
      ]
    end
  end
end
