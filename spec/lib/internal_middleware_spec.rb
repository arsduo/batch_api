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
    builder.instance_eval(&BatchApi::InternalMiddleware::DEFAULT_GLOBAL)
    builder.middlewares.should be_empty
  end

  it "builds a per-op middleware with the JSON decoder" do
    builder.instance_eval(&BatchApi::InternalMiddleware::DEFAULT_PER_OP)
    builder.middlewares.length.should == 1
    builder.middlewares.first.should ==
      [BatchApi::InternalMiddleware::DecodeJsonBody, []]
  end

  describe ".stack" do
    # we can't use stubs inside the procs since they're instance_eval'd
    let(:global_config) { Proc.new { use "Global" } }
    let(:op_config) { Proc.new { use "Op" } }
    let(:stack) { BatchApi::InternalMiddleware.stack }

    class Middleware; class Builder; end; end

    before :each do
      BatchApi.config.stub(:global_middleware).and_return(global_config)
      BatchApi.config.stub(:per_op_middleware).and_return(op_config)
      stub_const("Middleware::Builder", FakeBuilder)
    end

    it "builds the stack with the right number of wares" do
      stack.middlewares.length.should == 3
    end

    it "builds a middleware stack starting with the configured global wares" do
      stack.middlewares[0].first.should == "Global"
    end

    it "inserts the sequential processor" do
      stack.middlewares[1].first.should == BatchApi::Processor::Sequential
    end

    it "builds a middleware stack ending with the configured per-op wares" do
      stack.middlewares[2].first.should == "Op"
    end
  end
end
