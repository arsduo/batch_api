require 'spec_helper'

describe BatchApi::InternalMiddleware do
  class FakeBuilder
    attr_accessor :middlewares

    def initialize(&block)
      @middlewares = []
      instance_eval(&block) if block_given?
    end

    def use(middleware, *args)
      @middlewares << [middleware, args]
    end
  end

  let(:builder) { FakeBuilder.new }

  it "builds an empty default global middleware" do
    builder.instance_eval(
      &BatchApi::InternalMiddleware::DEFAULT_BATCH_MIDDLEWARE
    )
    builder.middlewares.should be_empty
  end

  describe "internal middleware defaults" do
    before :each do
      builder.instance_eval(
        &BatchApi::InternalMiddleware::DEFAULT_OPERATION_MIDDLEWARE
      )
    end

    it "builds a per-op middleware with the response silencer" do
      builder.middlewares[0].should ==
        [BatchApi::InternalMiddleware::ResponseFilter, []]
    end

    it "builds a per-op middleware with the JSON decoder" do
      builder.middlewares[1].should ==
        [BatchApi::InternalMiddleware::DecodeJsonBody, []]
    end
  end

  describe ".batch_stack" do
    # we can't use stubs inside the procs since they're instance_eval'd
    let(:global_config) { Proc.new { use "Global" } }
    let(:strategy) { stub("strategy") }
    let(:processor) { stub("processor", strategy: strategy) }
    let(:stack) { BatchApi::InternalMiddleware.batch_stack(processor) }

    before :each do
      BatchApi.config.stub(:batch_middleware).and_return(global_config)
      stub_const("Middleware::Builder", FakeBuilder)
    end

    it "builds the stack with the right number of wares" do
      stack.middlewares.length.should == 2
    end

    it "builds a middleware stack starting with the configured global wares" do
      stack.middlewares[0].first.should == "Global"
    end

    it "inserts the appropriate strategy from the processor" do
      stack.middlewares[1].first.should == strategy
    end
  end

  describe ".operation_stack" do
    # we can't use stubs inside the procs since they're instance_eval'd
    let(:op_config) { Proc.new { use "Op" } }
    let(:stack) { BatchApi::InternalMiddleware.operation_stack }

    before :each do
      BatchApi.config.stub(:operation_middleware).and_return(op_config)
      stub_const("Middleware::Builder", FakeBuilder)
    end

    it "builds the stack with the right number of wares" do
      stack.middlewares.length.should == 2
    end

    it "builds a middleware stack including the configured per-op wares" do
      stack.middlewares[0].first.should == "Op"
    end

    it "builds a middleware stack ending with the executor" do
      stack.middlewares[1].first.should == BatchApi::Processor::Executor
    end
  end
end
