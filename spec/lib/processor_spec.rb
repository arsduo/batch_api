require 'spec_helper'

describe BatchApi::Processor do

  let(:ops) { [ {"url" => "/endpoint", "method" => "get"} ] }
  let(:options) { { "sequential" => true } }
  let(:env) { {
    "CONTENT_TYPE"=>"application/x-www-form-urlencoded",
    "GATEWAY_INTERFACE"=>"CGI/1.1",
    "PATH_INFO"=>"/foo",
    "QUERY_STRING"=>"",
    "REMOTE_ADDR"=>"127.0.0.1",
    "REMOTE_HOST"=>"1035.spotilocal.com",
    "REQUEST_METHOD"=>"REPORT",
    "REQUEST_URI"=>"http://localhost:3000/batch",
    "SCRIPT_NAME"=>"",
    "rack.input" => StringIO.new,
    "rack.errors" => StringIO.new,
    "SERVER_NAME"=>"localhost",
    "SERVER_PORT"=>"3000",
    "SERVER_PROTOCOL"=>"HTTP/1.1",
    "SERVER_SOFTWARE"=>"WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)",
    "HTTP_USER_AGENT"=>"curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21",
    "HTTP_HOST"=>"localhost:3000"
  } }

  let(:request) {
    Rack::Request.new(env).tap do |r|
      r.stub(:params).and_return({}.merge("ops" => ops).merge(options))
    end
  }
  let(:app) { stub("application", call: [200, {}, ["foo"]]) }
  let(:processor) { BatchApi::Processor.new(request, app) }

  describe "#initialize" do
    # this may be brittle...consider refactoring?
    it "turns the ops params into processed operations at #ops" do
      # simulate receiving several operations
      klass = stub("op class")
      BatchApi::Processor.stub(:operation_klass).and_return(klass)
      operation_objects = 3.times.collect { stub("operation object") }
      operation_params = 3.times.collect do |i|
        stub("raw operation").tap do |o|
          klass.should_receive(:new)
            .with(o, env, app).and_return(operation_objects[i])
        end
      end

      request.params["ops"] = operation_params
      BatchApi::Processor.new(request, app).ops.should == operation_objects
    end

    it "makes the options available" do
      BatchApi::Processor.new(request, app).options.should == options
    end

    it "makes the app available" do
      BatchApi::Processor.new(request, app).app.should == app
    end

    context "error conditions" do

      it "raise a OperationLimitExceeded error if too many ops provided" do
        ops = (BatchApi.config.limit + 1).to_i.times.collect {|i| i}
        request.params["ops"] = ops
        expect {
          BatchApi::Processor.new(request, app)
        }.to raise_exception(BatchApi::Errors::OperationLimitExceeded)
      end

      it "raises a NoOperationError if operations.blank?" do
        request.params["ops"] = nil
        expect {
          BatchApi::Processor.new(request, app)
        }.to raise_exception(BatchApi::Errors::NoOperationsError)
        request.params["ops"] = []
        expect {
          BatchApi::Processor.new(request, app)
        }.to raise_exception(BatchApi::Errors::NoOperationsError)
      end
    end
  end

  describe "#strategy" do
    it "returns BatchApi::Processor::Sequential" do
      processor.strategy.should == BatchApi::Processor::Sequential
    end
    it "returns BatchApi::Processor::Parallel" do
      request = Rack::Request.new(env).tap do |r|
        r.stub(:params).and_return({}.merge("ops" => ops).merge("sequential" => false))
      end
      processor = BatchApi::Processor.new(request, app)
      processor.strategy.should == BatchApi::Processor::Parallel
    end
  end

  describe "#execute!" do
    let(:result) { stub("result") }
    let(:stack) { stub("stack", call: result) }
    let(:middleware_env) { {
      ops: processor.ops, # the processed Operation objects
      rack_env: env,
      rack_app: app,
      options: options
    } }

    before :each do
      BatchApi::InternalMiddleware.stub(:batch_stack).and_return(stack)
    end

    it "calls an internal middleware stacks with the appropriate data" do
      stack.should_receive(:call).with(middleware_env)
      processor.execute!
    end

    it "returns the formatted result of the strategy" do
      stack.stub(:call).and_return(stubby = stub)
      processor.execute!["results"].should == stubby
    end
  end

  describe ".operation_klass" do
    it "returns BatchApi::Operation::Rack if !Rails" do
      BatchApi.stub(:rails?).and_return(false)
      BatchApi::Processor.operation_klass.should ==
        BatchApi::Operation::Rack
    end

    it "returns BatchApi::Operation::Rails if Rails" do
      BatchApi.stub(:rails?).and_return(true)
      BatchApi::Processor.operation_klass.should ==
        BatchApi::Operation::Rails
    end
  end
end
