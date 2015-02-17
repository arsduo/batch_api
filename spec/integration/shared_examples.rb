shared_examples_for "a get request" do
  it "returns the body as objects" do
    @result = JSON.parse(response.body)["results"][0]
    @result["body"].should == get_result[:body]
  end

  it "returns the expected status" do
    @result["status"].should == get_result[:status]
  end

  it "returns the expected headers" do
    @result["headers"].should include(get_result[:headers])
  end

  it "verifies that the right headers were received" do
    @result["headers"]["REQUEST_HEADERS"].should include(
      headerize(get_headers)
    )
  end
end

shared_examples_for "integrating with a server" do |sequential|
  def headerize(hash)
    Hash[hash.map do |k, v|
      ["HTTP_#{k.to_s.upcase}", v.to_s]
    end]
  end

  before :all do
    BatchApi.config.endpoint = "/batch"
    BatchApi.config.verb = :post
  end

  before :each do
    BatchApi::ErrorWrapper.stub(:expose_backtrace?).and_return(false)
  end

  # these are defined in the dummy app's endpoints controller
  let(:get_headers) { {"foo" => "bar"} }
  let(:get_params) { {"other" => "value" } }

  let(:get_request) { {
    url: "/endpoint",
    method: "get",
    headers: get_headers,
    params: get_params
  } }

  let(:get_by_default_request) { {
    url: "/endpoint",
    headers: get_headers,
    params: get_params
  } }

  let(:get_result) { {
    status: 422,
    body: {
      "result" => "GET OK",
      "params" => get_params.merge(
        BatchApi.rails? ? {
          "controller" => "endpoints",
          "action" => "get"
        } : {}
      )
    },
    headers: { "GET" => "hello" }
  } }

  # these are defined in the dummy app's endpoints controller
  let(:post_headers) { {"foo" => "bar"} }
  let(:post_params) { {"other" => "value"} }

  let(:post_request) { {
    url: "/endpoint",
    method: "post",
    headers: post_headers,
    params: post_params
  } }

  let(:post_result) { {
    status: 203,
    body: {
      "result" => "POST OK",
      "params" => post_params.merge(
        BatchApi.rails? ? {
          "controller" => "endpoints",
          "action" => "post"
        } : {}
      )
    },
    headers: { "POST" => "guten tag" }
  } }

  let(:error_request) { {
    url: "/endpoint/error",
    method: "get"
  } }

  let(:error_response) { {
    status: 500,
    body: { "error" => { "message" => "StandardError" } }
  } }

  let(:missing_request) { {
    url: "/dont/work",
    method: "delete"
  } }

  let(:missing_response) { {
    status: 404,
    body: {}
  } }

  let(:parameter) {
    (rand * 10000).to_i
  }

  let(:parameter_request) { {
    url: "/endpoint/capture/#{parameter}",
    method: "get"
  } }

  let(:parameter_result) { {
    body: {
      "result" => parameter.to_s
    }
  } }

  let(:silent_request) { {
    url: "/endpoint",
    method: "post",
    silent: true
  } }

  let(:failed_silent_request) {
    error_request.merge(silent: true)
  }

  let(:failed_silent_result) {
    error_response
  }

  before :each do
    @t = Time.now
    xhr :post, "/batch", {
      ops: [
        get_request,
        post_request,
        error_request,
        missing_request,
        parameter_request,
        silent_request,
        failed_silent_request,
        get_by_default_request
      ],
      sequential: sequential
    }.to_json, "CONTENT_TYPE" => "application/json"
  end

  it "returns a 200" do
    response.status.should == 200
  end

  it "includes results" do
    JSON.parse(response.body)["results"].should be_a(Array)
  end

  context "for a get request" do
    describe "with an explicit get" do
      before :each do
        @result = JSON.parse(response.body)["results"][0]
      end

      it_should_behave_like "a get request"
    end

    describe "with no method" do
      before :each do
        @result = JSON.parse(response.body)["results"][7]
      end

      it_should_behave_like "a get request"
    end
  end

  context "for a request with parameters" do
    describe "the response" do
      before :each do
        @result = JSON.parse(response.body)["results"][4]
      end

      it "properly parses the URL segment as a paramer" do
        @result["body"].should == parameter_result[:body]
      end
    end
  end

  context "for a post request" do
    describe "the response" do
      before :each do
        @result = JSON.parse(response.body)["results"][1]
      end

      it "returns the body as objects (since DecodeJsonBody is default)" do
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
    end
  end

  context "for a request that returns an error" do
    before :each do
      @result = JSON.parse(response.body)["results"][2]
    end

    it "returns the right status" do
      @result["status"].should == error_response[:status]
    end

    it "returns the right error information" do
      # we don't care about the backtrace,
      # the main thing is that the messsage arrives
      @result["body"]["error"].should include(error_response[:body]["error"])
    end
  end

  context "for a request that returns error" do
    before :each do
      @result = JSON.parse(response.body)["results"][3]
    end

    it "returns the right status" do
      @result["status"].should == 404
    end
  end

  context "for a silent request" do
    before :each do
      @result = JSON.parse(response.body)["results"][5]
    end

    it "returns nothing" do
      @result.should == {}
    end
  end

  context "for a silent request that causes an error" do
    before :each do
      @result = JSON.parse(response.body)["results"][6]
    end

    it "returns a regular result" do
      @result.keys.should_not be_empty
    end
  end
end
