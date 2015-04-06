require 'spec_helper'

describe BatchApi::RackMiddleware do
  describe "#initialize" do
    it "allows access to the BatchApi configuration" do
      limit = rand * 100
      middleware = BatchApi::RackMiddleware.new(double("app")) do |conf|
        conf.limit = limit
      end
      expect(BatchApi.config.limit).to eq(limit)
    end
  end

  describe "#call" do
    let(:endpoint) { "/foo/bar" }
    let(:verb) { "run" }
    let(:app) { double("app") }

    let(:middleware) {
      BatchApi::RackMiddleware.new(app) do |conf|
        conf.endpoint = endpoint
        conf.verb = verb
      end
    }

    context "if it's a batch call" do
      let(:env) { {
        "PATH_INFO" => endpoint,
        "REQUEST_METHOD" => verb.upcase,
        # other stuff
        "CONTENT_TYPE"=>"application/x-www-form-urlencoded",
        "GATEWAY_INTERFACE"=>"CGI/1.1",
        "QUERY_STRING"=>"",
        "REMOTE_ADDR"=>"127.0.0.1",
        "REMOTE_HOST"=>"1035.spotilocal.com",
        "REQUEST_URI"=>"http://localhost:3000/batch",
        "SCRIPT_NAME"=>"",
        "rack.input" => StringIO.new,
        "rack.errors" => StringIO.new,
        "SERVER_NAME"=>"localhost",
        "SERVER_PORT"=>"3000",
        "SERVER_PROTOCOL"=>"HTTP/1.1",
        "SERVER_SOFTWARE"=>"WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)",
        "HTTP_USER_AGENT"=>"curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5",
        "HTTP_HOST"=>"localhost:3000"
      } }

      let(:request) { Rack::Request.new(env) }
      let(:result) { {a: 2, b: {c: 3}} }
      let(:processor) { double("processor", :execute! => result) }

      before :each do
        allow(BatchApi::Processor).to receive(:new).and_return(processor)
      end

      it "processes the batch request" do
        allow(Rack::Request).to receive(:new).with(env).and_return(request)
        expect(BatchApi::Processor).to receive(:new).with(request, app).and_return(processor)
        middleware.call(env)
      end

      context "for a successful set of calls" do
        it "returns the JSON-encoded result as the body" do
          output = middleware.call(env)
          expect(output[2]).to eq([MultiJson.dump(result)])
        end

        it "returns a 200" do
          expect(middleware.call(env)[0]).to eq(200)
        end

        it "sets the content type" do
          expect(middleware.call(env)[1]).to include("Content-Type" => "application/json")
        end
      end

      context "for BatchApi errors" do
        it "returns a rendered ErrorWrapper" do
          err, result = StandardError.new, double
          error = double("error object", render: result)
          allow(BatchApi::Processor).to receive(:new).and_raise(err)
          expect(BatchApi::ErrorWrapper).to receive(:new).with(err).and_return(
            error
          )
          expect(middleware.call(env)).to eq(result)
        end
      end
    end

    context "if it's not a batch request" do
      let(:env) { {
        "PATH_INFO" => "/not/batch",
        "REQUEST_METHOD" => verb.upcase
      } }

      it "just calls the app onward and returns the result" do
        output = double("output")
        expect(app).to receive(:call).with(env).and_return(output)
        middleware.call(env)
      end
    end
  end
end
