require 'spec_helper'

describe BatchApi::InternalMiddleware::DecodeJsonBody do
  let(:app) { stub("app", call: result) }
  let(:decoder) { BatchApi::InternalMiddleware::DecodeJsonBody.new(app) }
  let(:env) { stub("env") }
  let(:json) { {"data" => "is_json", "more" => {"hi" => "there"} } }
  let(:result) {
    [
      200,
      {"Content-Type" => "application/json"},
      MultiJson.dump(json)
    ]
  }

  describe "#call" do
    context "for json results" do
      it "decodes JSON results for application/json responses" do
        result = decoder.call(env)
        result[2].should == json
      end

      it "doesn't change anything else" do
        result = decoder.call(env)
        result[0].should == 200
        result[1].should == {"Content-Type" => "application/json"}
      end
    end

    context "for non-JSON responses" do
      it "doesn't decode" do
        result[1] = {"Content-Type" => "text/html"}
        decoder.call(env)[2].should == MultiJson.dump(json)
      end
    end
  end
end
