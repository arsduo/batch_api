require 'spec_helper'
require 'batch_api/operation'

describe BatchApi::Operation::Rack do
  let(:op_params) { {
    "method" => "POST",
    # this matches a route in our dummy application
    "url" => "/endpoint?foo=baz",
    "params" => {a: 2},
    "headers" => {"foo" => "bar"}
  } }

  # for env, see bottom of file - it's long
  let(:operation) { BatchApi::Operation::Rack.new(op_params, env, app) }
  let(:app) { double("application", call: [200, {}, ["foo"]]) }

  describe "accessors" do
    [
      :method, :url, :params, :headers,
      :env, :app, :result, :options
    ].each do |a|
      attr = a
      it "has an accessor for #{attr}" do
        value = double
        operation.send("#{attr}=", value)
        expect(operation.send(attr)).to eq(value)
      end
    end
  end

  describe "#initialize" do
    ["method", "url", "params", "headers"].each do |a|
      attr = a
      it "extracts the #{attr} information from the operation params" do
        expect(operation.send(attr)).to eq(op_params[attr])
      end
    end

    it "sets options to the op" do
      expect(operation.options).to eq(op_params)
    end

    it "defaults method to get if not provided" do
      op = BatchApi::Operation::Rack.new(op_params.except("method"), env, app)
      expect(op.method).to eq("get")
    end

    it "defaults params to {} if not provided" do
      op = BatchApi::Operation::Rack.new(op_params.except("params"), env, app)
      expect(op.params).to eq({})
    end

    it "defaults headers to {} if not provided" do
      op = BatchApi::Operation::Rack.new(op_params.except("headers"), env, app)
      expect(op.headers).to eq({})
    end

    it "does a deep dup of the env" do
      expect(operation.env).to eq(env)

      flat_env = env.to_a.flatten
      operation.env.to_a.flatten.each_with_index do |obj, index|
        # this is a rough test for deep dup -- make sure the objects
        # that aren't symbols aren't actually the same objects in memory
        if obj.is_a?(Hash) || obj.is_a?(Array)
          expect(obj.object_id).not_to eq(flat_env[index].object_id)
        end
      end
    end

    it "raises a MalformedOperationError if URL is missing" do
      no_url = op_params.dup.tap {|o| o.delete("url") }
      expect {
        BatchApi::Operation::Rack.new(no_url, env, app)
      }.to raise_exception(BatchApi::Errors::MalformedOperationError)
    end
  end

  describe "#process_env" do
    let(:processed_env) { operation.tap {|o| o.process_env}.env }

    before { BatchApi.config.stub(endpoint: '/api/batch') }

    it "merges any headers in in the right format" do
      key = "HTTP_FOO" # as defined above in op_params

      expect(processed_env[key]).not_to eq(env[key])
      # in this case, it's a batch controller
      expect(processed_env[key]).to eq(op_params["headers"]["foo"])
    end

    it "preserves existing headers" do
      expect(processed_env["HTTP_PREVIOUS_HEADERS"]).to eq(env["HTTP_PREVIOUS_HEADERS"])
    end

    it "updates the method" do
      key = "REQUEST_METHOD"
      expect(processed_env[key]).not_to eq(env[key])
      expect(processed_env[key]).to eq("POST")
    end

    it "updates the REQUEST_URI" do
      key = "REQUEST_URI"
      expect(processed_env[key]).not_to eq(env[key])
      expect(processed_env[key]).to eq("http://localhost:3000#{op_params["url"]}")
    end

    it "works if REQUEST_URI is blank" do
      key = "REQUEST_URI"
      env.delete(key)
      expect(processed_env[key]).to be_nil
    end

    it "updates the REQUEST_PATH with the path component (w/o params)" do
      key = "REQUEST_PATH"
      expect(processed_env[key]).not_to eq(env[key])
      expect(processed_env[key]).to eq(op_params["url"].split("?").first)
    end

    it "updates the original fullpath" do
      key = "ORIGINAL_FULLPATH"
      expect(processed_env[key]).not_to eq(env[key])
      expect(processed_env[key]).to eq(op_params["url"])
    end

    it "updates the PATH_INFO" do
      key = "PATH_INFO"
      expect(processed_env[key]).not_to eq(env[key])
      expect(processed_env[key]).to eq(op_params["url"])
    end

    it "updates the rack query string" do
      key = "rack.request.query_string"
      expect(processed_env[key]).not_to eq(env[key])
      expect(processed_env[key]).to eq(op_params["url"].split("?").last)
    end

    it "updates the QUERY_STRING" do
      key = "QUERY_STRING"
      expect(processed_env[key]).not_to eq(env[key])
      expect(processed_env[key]).to eq(op_params["url"].split("?").last)
    end

    it "updates the form hash" do
      key = "rack.request.form_hash"
      expect(processed_env[key]).not_to eq(env[key])
      expect(processed_env[key]).to eq(op_params["params"])
    end

    context "query_hash" do
      it "sets it to params for a GET" do
        operation.method = "get"
        processed_env = operation.tap {|o| o.process_env}.env
        key = "rack.request.query_hash"
        expect(processed_env[key]).not_to eq(env[key])
        expect(processed_env[key]).to eq(op_params["params"])
      end

      it "sets it to nil for a POST" do
        key = "rack.request.query_hash"
        expect(processed_env[key]).not_to eq(env[key])
        expect(processed_env[key]).to be_nil
      end
    end
  end

  describe "#execute" do
    context "when it works" do
      let(:result) { [
        200,
        {header: "footer"},
        double(body: "{\"data\":2}", cookies: nil)
      ] }
      let(:processed_env) { double }

      before :each do
        allow(operation).to receive(:process_env) { operation.env = processed_env }
      end

      it "executes the call with the application" do
        expect(app).to receive(:call).with(processed_env)
        operation.execute
      end

      it "returns a BatchAPI::Response made from the result" do
        response = double
        allow(app).to receive(:call).and_return(result)
        expect(BatchApi::Response).to receive(:new).with(result).and_return(response)
        expect(operation.execute).to eq(response)
      end

      it "returns a BatchApi::Response from an ErrorWrapper for errors" do
        err = StandardError.new
        result, rendered, response = double, double, double
        b_err = double("batch error", render: rendered)

        # simulate the error
        allow(app).to receive(:call).and_raise(err)
        # we'll create the BatchError
        expect(BatchApi::ErrorWrapper).to receive(:new).with(err).and_return(b_err)
        # render that as the response
        expect(BatchApi::Response).to receive(:new).with(rendered).and_return(response)
        # and return the response overall
        expect(operation.execute).to eq(response)
      end
    end
  end

  let(:env) {
    {
      "CONTENT_LENGTH"=>"10",
      "CONTENT_TYPE"=>"application/x-www-form-urlencoded",
      "GATEWAY_INTERFACE"=>"CGI/1.1",
      "PATH_INFO"=>"/foo",
      "QUERY_STRING"=>"",
      "REMOTE_ADDR"=>"127.0.0.1",
      "REMOTE_HOST"=>"1035.spotilocal.com",
      "REQUEST_METHOD"=>"REPORT",
      "REQUEST_URI"=>"http://localhost:3000/api/batch",
      "SCRIPT_NAME"=>"",
      "SERVER_NAME"=>"localhost",
      "SERVER_PORT"=>"3000",
      "SERVER_PROTOCOL"=>"HTTP/1.1",
      "SERVER_SOFTWARE"=>"WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)",
      "HTTP_USER_AGENT"=>"curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5",
      "HTTP_HOST"=>"localhost:3000",
      "HTTP_ACCEPT"=>"*/*",
      "HTTP_PREVIOUS_HEADERS" => "value",
      "rack.version"=>[1,1],
      "rack.input"=>StringIO.new("{\"ops\":{}}"),
      "rack.errors"=>$stderr,
      "rack.multithread"=>false,
      "rack.multiprocess"=>false,
      "rack.run_once"=>false,
      "rack.url_scheme"=>"http",
      "HTTP_VERSION"=>"HTTP/1.1",
      "REQUEST_PATH"=>"/api/batch",
      "ORIGINAL_FULLPATH"=>"/api/batch",
      "rack.request.form_input"=>StringIO.new("{\"ops\":{}}"),
      "rack.request.form_hash"=>{"{\"ops\":{}}"=>nil},
      "rack.request.form_vars"=>"{\"ops\":{}}",
      "rack.request.query_string"=>"",
      "rack.request.query_hash"=>{}
    }
  }
end
