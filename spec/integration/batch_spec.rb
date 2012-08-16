require 'spec_helper'

describe "Batch API integration specs" do
  def headerize(hash)
    Hash[hash.map do |k, v|
      ["HTTP_#{k.to_s.upcase}", v.to_s]
    end]
  end

  before :all do
    BatchApi.config.endpoint = "/batch"
    BatchApi.config.verb = :post
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

  # these are defined in the dummy app's endpoints controller
  let(:post_headers) { {foo: :bar} }
  let(:post_params) { {other: :value } }

  let(:post_request) { {
    url: "/endpoint",
    method: "post",
    headers: post_headers,
    params: post_params
  } }

  let(:post_result) { {
    status: 203,
    body: {
      result: "POST OK",
      params: post_params
    },
    headers: { "POST" => "guten tag" },
    cookies: { "POST" => "tschussikowski" }
  } }

  let(:error_request) { {
    url: "/endpoint/error",
    method: "get"
  } }

  let(:error_response) { {
    status: 500,
    body: { error: { message: "StandardError" } }
  } }

  let(:missing_request) { {
    url: "/dont/work",
    method: "delete"
  } }

  let(:missing_response) { {
    status: 404,
    body: {}
  } }

  before :each do
    xhr :post, "/batch", {
      ops: [
        get_request,
        post_request,
        error_request,
        missing_request
      ],
      sequential: true
    }.to_json, "CONTENT_TYPE" => "application/json"
  end

  it "returns a 200" do
    response.status.should == 200
  end

  context "for a get request" do
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
        @result["headers"]["REQUEST_HEADERS"].should include(headerize(get_headers))
      end
    end
  end

  context "for a post request" do
    describe "the response" do
      before :each do
        @result = JSON.parse(response.body)[1]
      end

      it "returns the expected body raw if BatchApi.config.decode_body = false" do
        # BatchApi.config.decode_bodies = false
        body = JSON.parse(@result["body"])
        body.should == JSON.parse(post_result[:body].to_json)
      end

      pending "returns the expected body as objects if BatchApi.config.decode_body = true" do
        xhr :post, "/batch", {ops: [post_request]}.to_json, "CONTENT_TYPE" => "application/json"
        @result = JSON.parse(response.body)[0]
        @result["body"].should == post_result[:body]
      end

      it "returns the expected status" do
        @result["status"].should == post_result[:status]
      end

      it "returns the expected headers" do
        @result["headers"].should include(post_result[:headers])
      end

      it "verifies that the right headers were received" do
        @result["headers"]["REQUEST_HEADERS"].should include(headerize(post_headers))
      end

      pending "returns the expected cookies" do
        @result["cookies"].should include(post_result[:cookies])
      end
    end
  end

  context "for a request that returns error" do
    before :each do
      @result = JSON.parse(response.body)[2]
    end

    it "returns the right status" do
      @result["status"].should == error_response[:status]
    end

    it "returns the right status" do
      @result["body"].should == error_response[:body].to_json
    end
  end

  context "for a request that returns error" do
    before :each do
      @result = JSON.parse(response.body)[3]
    end

    it "returns the right status" do
      @result["status"].should == 404
    end
  end
end
