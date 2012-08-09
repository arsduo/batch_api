require 'spec_helper'
require 'batch_api/operation'

describe BatchApi::Operation do
  let(:op_params) { { method: "POST", url: "/batch?foo=baz", params: {a: 2}, headers: {"foo" => "bar"} } }
  # for env, see bottom of file - it's long
  let(:operation) { BatchApi::Operation.new(op_params, env) }
  let(:path_params) { {controller: "batch_api/batch", action: "batch"} }

  describe "accessors" do
    [:method, :url, :params, :headers, :env, :result].each do |a|
      attr = a
      it "has an accessor for #{attr}" do
        value = stub
        operation.send("#{attr}=", value)
        operation.send(attr).should == value
      end
    end
  end

  describe "#initialize" do
    [:method, :url, :params, :headers].each do |a|
      attr = a
      it "extracts the #{attr} information from the operation params" do
        operation.send(attr).should == op_params[attr]
      end
    end

    it "does a deep dup of the env" do
      operation.env.should == env

      flat_env = env.to_a.flatten
      operation.env.to_a.flatten.each_with_index do |obj, index|
        # this is a rough test for deep dup -- make sure the objects
        # that aren't symbols aren't actually the same objects in memory
        puts "obj: #{obj}, #{obj.class}"
        if obj.is_a?(Hash) || obj.is_a?(Array)
          obj.object_id.should_not == flat_env[index].object_id
        end
      end
    end
  end

  describe "#identify_routing" do
    # this is hard to test, since it's testing rails internals
    # so we'll just verify we get a callable object, and the rest
    # we'll save for integration tests
    it "gets an action object which can be called" do
      Rails.application.routes.stub(:recognize_path).and_return(path_params)
      operation.identify_routing.should respond_to(:call)
    end
  end

  describe "#process_env" do
    before :each do
      operation.identify_routing
    end

    let(:processed_env) { operation.tap {|o| o.process_env}.env }

    # long and boring and possibly brittle tests
    it "updates the controller with the path parameters" do
      key = "action_dispatch.request.path_parameters"
      processed_env[key].should_not == env[key]
      processed_env[key].keys.should include(:action, :controller)
    end

    it "updates the controller with the controller instance" do
      key = "action_controller.instance"
      processed_env[key].should_not == env[key]
      # in this case, it's a batch controller
      processed_env[key].should be_a(BatchApi::BatchController)
    end

    it "merges any headers in " do
      key = "HTTP_FOO" # as defined above in op_params

      processed_env[key].should_not == env[key]
      # in this case, it's a batch controller
      processed_env[key].should == op_params[:headers]["foo"]
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
