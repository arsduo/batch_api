require 'spec_helper'

describe BatchApi::InternalMiddleware::DecodeJsonBody do
  let(:app) { double("app", call: result) }
  let(:decoder) { BatchApi::InternalMiddleware::DecodeJsonBody.new(app) }
  let(:env) { double("env") }
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
        expect(result.body).to eq(json)
      end

      it "doesn't change anything else" do
        result = decoder.call(env)
        expect(result.status).to eq(200)
        expect(result.headers).to eq({"Content-Type" => "application/json"})
      end
    end

    context "for non-JSON responses" do
      it "doesn't decode" do
        result.headers = {"Content-Type" => "text/html"}
        expect(decoder.call(env).body).to eq(MultiJson.dump(json))
      end
    end

    context "for empty responses" do
      it "doesn't try to parse" do
        result.body = ""
        expect(decoder.call(env).body).to eq("")
      end
    end
  end
end
