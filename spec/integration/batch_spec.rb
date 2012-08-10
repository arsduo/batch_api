require 'spec_helper'

describe "Batch API integration specs" do
  def headerify(hash)
    Hash[hash.map do |k, v|
      ["HTTP_#{k.to_s.upcase}", v.to_s]
    end]
  end

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
      params: get_params
    },
    headers: { "GET" => "hello" },
    cookies: { "GET" => "bye" }
  } }


  context "for a get request" do
    before :each do
      xhr :post, "/batch", {ops: [get_request]}.to_json, "CONTENT_TYPE" => "application/json"
    end

    it "returns a 200" do
      response.status.should == 200
    end

    describe "the response" do
      before :each do
        @result = JSON.parse(response.body)[0]
      end

      it "returns the expected body raw if BatchApi.config.decode_body = false" do
        # BatchApi.config.decode_bodies = false
        body = JSON.parse(@result["body"])
        body.should == JSON.parse(get_result[:body].to_json)
      end

      pending "returns the expected body as objects if BatchApi.config.decode_body = true" do
        xhr :post, "/batch", {ops: [get_request]}.to_json, "CONTENT_TYPE" => "application/json"
        @result = JSON.parse(response.body)[0]
        @result["body"].should == get_result[:body]
      end

      it "returns the expected status" do
        @result["status"].should == get_result[:status]
      end

      it "returns the expected headers" do
        @result["headers"].should include(get_result[:headers])
      end

      it "verifies that the right headers were received" do
        @result["headers"]["REQUEST_HEADERS"].should include(headerify(get_headers))
      end

      pending "returns the expected cookies" do
        @result["cookies"].should include(get_result[:cookies])
      end
    end
  end

end
