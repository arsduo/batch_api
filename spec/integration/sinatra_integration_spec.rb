require 'spec_helper'
require 'support/sinatra_app'
require 'rack/test'

describe "Sinatra integration" do
  include Rack::Test::Methods

  def app
    SinatraApp
  end

  def headerize(hash)
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
    body: { error: true }
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
    end
  end

=begin
  def test_my_default
    get '/'
    assert_equal 'Hello World!', last_response.body
  end

  def test_with_params
    get '/meet', :name => 'Frank'
    assert_equal 'Hello Frank!', last_response.body
  end

  def test_with_rack_env
    get '/', {}, 'HTTP_USER_AGENT' => 'Songbird'
    assert_equal "You're using Songbird!", last_response.body
  end
=end
end

