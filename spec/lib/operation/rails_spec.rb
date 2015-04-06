require 'spec_helper'
require 'batch_api/operation'

describe BatchApi::Operation::Rails do
  let(:op_params) { {
    "method" => "POST",
    # this matches a route in our dummy application
    "url" => "/endpoint?foo=baz",
    "params" => {a: 2},
    "headers" => {"foo" => "bar"}
  } }

  # for env, see bottom of file - it's long
  let(:operation) { BatchApi::Operation::Rails.new(op_params, env, app) }
  let(:app) { double("application", call: [200, {}, ["foo"]]) }
  let(:path_params) { {controller: "batch_api/batch", action: "batch"} }
  let(:mixed_params) { op_params["params"].merge(path_params) }

  before :each do
    allow(::Rails.application.routes).to receive(:recognize_path).and_return(path_params)
  end

  describe "#initialize" do
    it "merges in the Rails path params" do
      expect(::Rails.application.routes).to receive(:recognize_path).with(
        op_params["url"],
        op_params
      ).and_return(path_params)

      expect(operation.params).to include(path_params)
    end

    it "doesn't change the params if the path isn't recognized" do
      allow(::Rails.application.routes).to receive(:recognize_path).and_raise(StandardError)
      expect(operation.params).to eq(op_params["params"])
    end
  end

  describe "#process_env" do
    let(:processed_env) { operation.tap {|o| o.process_env}.env }

    it "updates the ActionDispatch params" do
      key = "action_dispatch.request.parameters"
      expect(processed_env[key]).not_to eq(env[key])
      expect(processed_env[key]).to eq(mixed_params)
    end

    it "updates the ActionDispatch request params" do
      key = "action_dispatch.request.request_parameters"
      expect(processed_env[key]).not_to eq(env[key])
      expect(processed_env[key]).to eq(mixed_params)
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
      "rack.request.query_string"=>"",
      "rack.request.query_hash"=>{}
    }
  }
end