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

  describe "#initialize" do
    it "sets status to the HTTP status code" do
      response.status.should == raw_response.first
    end

    it "sets body to the HTTP body turned into a string" do
      response.body.should == raw_response[2].join
    end

    it "sets headers to the HTTP headers" do
      response.headers.should == raw_response[1]
    end
  end

  describe "#as_json" do
    it "creates the expected hash" do
      response.as_json.should == {
        body: response.body,
        status: response.status,
        headers: response.headers
      }
    end

    it "accepts options" do
      response.as_json(foo: :bar).should_not be_nil
    end

    it "leaves out items that are blank" do
      response.status = response.body = nil
      response.as_json.should == {headers: raw_response[1]}
    end

    it "includes items that are false" do
      response.body = false
      response.as_json[:body].should == false
    end
  end
end
