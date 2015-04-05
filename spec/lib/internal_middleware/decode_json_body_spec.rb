require 'spec_helper'

describe BatchApi::InternalMiddleware::DecodeJsonBody do
  let(:app) { stub("app", call: result) }
  let(:decoder) { BatchApi::InternalMiddleware::DecodeJsonBody.new(app) }
  let(:env) { stub("env") }
  let(:json) { {"data" => "is_json", "more" => {"hi" => "there"} } }
  let(:result) {
    BatchApi::Response.new([
      200,
      {"Content-Type" => "application/json"},
      [MultiJson.dump(json)]
    ])
  }

  describe "#call" do
    context "for json results" do
      it "decodes JSON results for application/json responses" do
        result = decoder.call(env)
        result.body.should == json
      end

      it "doesn't change anything else" do
        result = decoder.call(env)
        result.status.should == 200
        result.headers.should == {"Content-Type" => "application/json"}
      end
    end

    context "for non-JSON responses" do
      it "doesn't decode" do
        result.headers = {"Content-Type" => "text/html"}
        decoder.call(env).body.should == MultiJson.dump(json)
      end
    end

    context "for empty responses" do
      it "doesn't try to parse" do
        result.body = ""
        decoder.call(env).body.should == ""
      end
    end
  end
end
