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
      allow(r).to receive(:params).and_return({}.merge("ops" => ops).merge(options))
    end
  }
  let(:app) { double("application", call: [200, {}, ["foo"]]) }
  let(:processor) { BatchApi::Processor.new(request, app) }

  describe "#initialize" do
    # this may be brittle...consider refactoring?
    it "turns the ops params into processed operations at #ops" do
      # simulate receiving several operations
      klass = double("op class")
      allow(BatchApi::Processor).to receive(:operation_klass).and_return(klass)
      operation_objects = 3.times.collect { double("operation object") }
      operation_params = 3.times.collect do |i|
        double("raw operation").tap do |o|
          expect(klass).to receive(:new)
            .with(o, env, app).and_return(operation_objects[i])
        end
      end

      request.params["ops"] = operation_params
      expect(BatchApi::Processor.new(request, app).ops).to eq(operation_objects)
    end

    it "makes the options available" do
      expect(BatchApi::Processor.new(request, app).options).to eq(options)
    end

    it "makes the app available" do
      expect(BatchApi::Processor.new(request, app).app).to eq(app)
    end

    context "error conditions" do
      it "(currently) throws an error if sequential is not true" do
        request.params.delete("sequential")
        expect {
          BatchApi::Processor.new(request, app)
        }.to raise_exception(BatchApi::Errors::BadOptionError)
      end

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
      expect(processor.strategy).to eq(BatchApi::Processor::Sequential)
    end
  end

  describe "#execute!" do
    let(:result) { double("result") }
    let(:stack) { double("stack", call: result) }
    let(:middleware_env) { {
      ops: processor.ops, # the processed Operation objects
      rack_env: env,
      rack_app: app,
      options: options
    } }

    before :each do
      allow(BatchApi::InternalMiddleware).to receive(:batch_stack).and_return(stack)
    end

    it "calls an internal middleware stacks with the appropriate data" do
      expect(stack).to receive(:call).with(middleware_env)
      processor.execute!
    end

    it "returns the formatted result of the strategy" do
      allow(stack).to receive(:call).and_return(stubby = double)
      expect(processor.execute!["results"]).to eq(stubby)
    end
  end

  describe ".operation_klass" do
    it "returns BatchApi::Operation::Rack if !Rails" do
      allow(BatchApi).to receive(:rails?).and_return(false)
      expect(BatchApi::Processor.operation_klass).to eq(
        BatchApi::Operation::Rack
      )
    end

    it "returns BatchApi::Operation::Rails if Rails" do
      allow(BatchApi).to receive(:rails?).and_return(true)
      expect(BatchApi::Processor.operation_klass).to eq(
        BatchApi::Operation::Rails
      )
    end
  end
end
