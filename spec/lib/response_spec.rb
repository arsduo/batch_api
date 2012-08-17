require 'spec_helper'
require 'batch_api/response'

describe BatchApi::Response do

  let(:raw_response) { [200, {}, ["ab", "cd", "ef"]] }
  let(:response) { BatchApi::Response.new(raw_response) }

  [:status, :body, :headers].each do |attr|
    local_attr = attr
    it "has an accessor for #{local_attr}" do
      response.should respond_to(local_attr)
    end
  end

  it "sets status to the HTTP status code" do
    response.status.should == raw_response.first
  end

  it "sets headers to the HTTP headers" do
    response.headers.should == raw_response[1]
  end

  describe "the body" do
    context "for non-JSON requests" do
      before :each do
        raw_response[1]["Content-Type"] = "text/html"
      end

      it "sets body to the string representation of the response body" do
        response.body.should == raw_response[2].join
      end
    end

    context "for JSON responses" do
      let(:json) { {"a" => 2, "b" => {"c" => 3}} }

      before :each do
        raw_response[1]["Content-Type"] = "application/json"
        raw_response[2] = [json.to_json]
      end

      it "decodes the body if the decode_json_responses is set" do
        response.body.should == json
      end

      it "doesn't decode the body if decode_json_responses is false" do
        BatchApi.config.stub(:decode_json_responses).and_return(false)
        response.body.should == json.to_json
      end
    end
  end
end
