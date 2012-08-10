require 'spec_helper'

describe "Batch API integration specs" do
  # these are defined in the dummy app's endpoints controller
  let(:get_headers) { {foo: :bar} }
  let(:get_params) { {other: :value } }

  let(:get_request) { {
    url: "/endpoint",
    method: "get",
    headers: get_headers,
    params: get_params
  } }

  let(:get_result) { {
    status: 422,
    body: {
      result: "GET OK",
      headers: get_headers,
      params: get_params
    },
    cookies: { "GET" => "hi" }
  } }


  context "for a get request" do
    it "returns a 200" do
      xhr :post, "/batch", {ops: [get_request]}.to_json, "CONTENT_TYPE" => "application/json"
      response.status.should == 200
    end

    context "if BatchApi.config.decode_body = false" do
      it "returns the expected body raw" do
        BatchApi.config.decode_bodies = false
        xhr :post, "/batch", {ops: [get_request]}.to_json, "CONTENT_TYPE" => "application/json"
        @result = JSON.parse(response.body)[0]
        body = JSON.parse(response.body)
        body.should == get_result[:body]
      end
    end

    context "if BatchApi.config.decode_body = false" do
      it "returns the expected body as objects" do
        xhr :post, "/batch", {ops: [get_request]}.to_json, "CONTENT_TYPE" => "application/json"
        @result = JSON.parse(response.body)[0]
        @result["body"].should == get_result[:body]
      end
    end
=begin
    it "returns the expected status" do
      @result["status"].should == get_result[:status]
    end

    it "returns the expected headers" do
      @result["headers"].should include(get_result[:headers])
    end
=end
    pending "returns the expected cookies" do
      @result["cookies"].should include(get_result[:cookies])
    end
  end

end
