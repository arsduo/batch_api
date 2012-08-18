require 'spec_helper'
require 'batch_api/operation'

describe BatchApi::Operation do
  let(:op_params) { {
    "method" => "POST",
    # this matches a route in our dummy application
    "url" => "/endpoint?foo=baz",
    "params" => {a: 2},
    "headers" => {"foo" => "bar"}
  } }

  # for env, see bottom of file - it's long
  let(:operation) { BatchApi::Operation.new(op_params, env, app) }
  let(:app) { stub("application", call: [200, {}, ["foo"]]) }
  let(:path_params) { {controller: "batch_api/batch", action: "batch"} }

  describe "accessors" do
    ["method", "url", "params", "headers", :env, :app, :result].each do |a|
      attr = a
      it "has an accessor for #{attr}" do
        value = stub
        operation.send("#{attr}=", value)
        operation.send(attr).should == value
      end
    end
  end

  describe "#initialize" do
    ["method", "url", "params", "headers"].each do |a|
      attr = a
      it "extracts the #{attr} information from the operation params" do
        operation.send(attr).should == op_params[attr]
      end
    end

    it "defaults params to {} if not provided" do
      op = BatchApi::Operation.new(op_params.except("params"), env, app)
      op.params.should == {}
    end

    it "defaults headers to {} if not provided" do
      op = BatchApi::Operation.new(op_params.except("headers"), env, app)
      op.headers.should == {}
    end

    it "does a deep dup of the env" do
      operation.env.should == env

      flat_env = env.to_a.flatten
      operation.env.to_a.flatten.each_with_index do |obj, index|
        # this is a rough test for deep dup -- make sure the objects
        # that aren't symbols aren't actually the same objects in memory
        if obj.is_a?(Hash) || obj.is_a?(Array)
          obj.object_id.should_not == flat_env[index].object_id
        end
      end
    end

    it "raises a MalformedOperationError if method or URL are missing" do
      no_method = op_params.dup.tap {|o| o.delete("method") }
      expect {
        BatchApi::Operation.new(no_method, env, app)
      }.to raise_exception(BatchApi::Operation::MalformedOperationError)

      no_url = op_params.dup.tap {|o| o.delete("url") }
      expect {
        BatchApi::Operation.new(no_url, env, app)
      }.to raise_exception(BatchApi::Operation::MalformedOperationError)

      nothing = op_params.dup.tap {|o| o.delete("url"); o.delete("method") }
      expect {
        BatchApi::Operation.new(nothing, env, app)
      }.to raise_exception(BatchApi::Operation::MalformedOperationError)
    end
  end

  describe "#process_env" do
    let(:processed_env) { operation.tap {|o| o.process_env}.env }

    it "merges any headers in in the right format" do
      key = "HTTP_FOO" # as defined above in op_params

      processed_env[key].should_not == env[key]
      # in this case, it's a batch controller
      processed_env[key].should == op_params["headers"]["foo"]
    end

    it "preserves existing headers" do
      processed_env["HTTP_PREVIOUS_HEADERS"].should == env["HTTP_PREVIOUS_HEADERS"]
    end

    it "updates the method" do
      key = "REQUEST_METHOD"
      processed_env[key].should_not == env[key]
      processed_env[key].should == "POST"
    end

    it "updates the REQUEST_URI" do
      key = "REQUEST_URI"
      processed_env[key].should_not == env[key]
      processed_env[key].should == env["REQUEST_URI"].gsub(/\/batch.*/, op_params["url"])
    end

    it "updates the REQUEST_PATH with the path component (w/o params)" do
      key = "REQUEST_PATH"
      processed_env[key].should_not == env[key]
      processed_env[key].should == op_params["url"].split("?").first
    end

    it "updates the original fullpath" do
      key = "ORIGINAL_FULLPATH"
      processed_env[key].should_not == env[key]
      processed_env[key].should == op_params["url"]
    end

    it "updates the PATH_INFO" do
      key = "PATH_INFO"
      processed_env[key].should_not == env[key]
      processed_env[key].should == op_params["url"]
    end

    it "updates the rack query string" do
      key = "rack.request.query_string"
      processed_env[key].should_not == env[key]
      processed_env[key].should == op_params["url"].split("?").last
    end

    it "updates the QUERY_STRING" do
      key = "QUERY_STRING"
      processed_env[key].should_not == env[key]
      processed_env[key].should == op_params["url"].split("?").last
    end

    it "updates the form hash" do
      key = "rack.request.form_hash"
      processed_env[key].should_not == env[key]
      processed_env[key].should == op_params["params"]
    end

    it "updates the ActionDispatch params" do
      key = "action_dispatch.request.parameters"
      processed_env[key].should_not == env[key]
      processed_env[key].should == op_params["params"]
    end

    it "updates the ActionDispatch request params" do
      key = "action_dispatch.request.request_parameters"
      processed_env[key].should_not == env[key]
      processed_env[key].should == op_params["params"]
    end

    context "query_hash" do
      it "sets it to params for a GET" do
        operation.method = "get"
        processed_env = operation.tap {|o| o.process_env}.env
        key = "rack.request.query_hash"
        processed_env[key].should_not == env[key]
        processed_env[key].should == op_params["params"]
      end

      it "sets it to nil for a POST" do
        key = "rack.request.query_hash"
        processed_env[key].should_not == env[key]
        processed_env[key].should be_nil
      end
    end
  end

  describe "#execute" do
    context "when it works" do
      let(:result) { [
        200,
        {header: "footer"},
        stub(body: "{\"data\":2}", cookies: nil)
      ] }
      let(:processed_env) { stub }

      before :each do
        operation.stub(:process_env) { operation.env = processed_env }
      end

      it "executes the call with the application" do
        app.should_receive(:call).with(processed_env)
        operation.execute
      end

      it "returns a BatchAPI::Response made from the result" do
        response = stub
        app.stub(:call).and_return(result)
        BatchApi::Response.should_receive(:new).with(result).and_return(response)
        operation.execute.should == response
      end

      it "returns a BatchApi::Response from a BatchError for errors" do
        err = StandardError.new
        result, rendered, response = stub, stub, stub
        b_err = stub("batch error", render: rendered)

        # simulate the error
        app.stub(:call).and_raise(err)
        # we'll create the BatchError
        BatchApi::Error.should_receive(:new).with(err).and_return(b_err)
        # render that as the response
        BatchApi::Response.should_receive(:new).with(rendered).and_return(response)
        # and return the response overall
        operation.execute.should == response
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
      "REQUEST_URI"=>"http://localhost:3000/batch",
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
      "REQUEST_PATH"=>"/batch",
      "ORIGINAL_FULLPATH"=>"/batch",
      "action_dispatch.routes"=>Rails.application.routes,
      "action_dispatch.parameter_filter"=>[:password],
      "action_dispatch.secret_token"=>"fc6fbc81b3204410da8389",
      "action_dispatch.show_exceptions"=>true,
      "action_dispatch.show_detailed_exceptions"=>true,
      "action_dispatch.logger"=>Rails.logger,
      "action_dispatch.backtrace_cleaner"=>nil,
      "action_dispatch.request_id"=>"2e7c988bea73e13dca4fac059a1bb187",
      "action_dispatch.remote_ip"=>"127.0.0.1",
      "action_dispatch.request.content_type"=>"application/x-www-form-urlencoded",
      "action_dispatch.request.path_parameters"=> {},
      # pick something that's not right
      "action_controller.instance"=>ApplicationController.new,
      "rack.request.form_input"=>StringIO.new("{\"ops\":{}}"),
      "rack.request.form_hash"=>{"{\"ops\":{}}"=>nil},
      "rack.request.form_vars"=>"{\"ops\":{}}",
      "action_dispatch.request.request_parameters"=>{"{\"ops\":{}}"=>nil},
      "rack.request.query_string"=>"",
      "rack.request.query_hash"=>{},
      "action_dispatch.request.query_parameters"=>{},
      "action_dispatch.request.parameters"=>{"{\"ops\":{}}"=>nil},
      "action_dispatch.request.accepts"=>"[*/*]",
      "action_dispatch.request.formats"=>"[*/*]"
    }
  }
end
