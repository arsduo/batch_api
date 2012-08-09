require 'spec_helper'
require 'batch_api/response'

describe BatchApi::Response do

  let(:raw_response) { [200, {}, Struct.new(:body, :cookies).new(:body, :cookies)] }
  let(:response) { BatchApi::Response.new(raw_response) }

  [:status, :body, :headers, :cookies].each do |attr|
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

  it "sets body to the body attributes" do
    response.body.should == :body
  end

  it "sets cookies to the cookies attributes" do
    response.cookies.should == :cookies
  end
end
