require 'spec_helper'
require 'batch_api/error'

describe BatchApi::Error do
  let(:exception) {
    StandardError.new(Faker::Lorem.words(3)).tap do |e|
      e.set_backtrace(Kernel.caller)
    end
  }

  let(:error) { BatchApi::Error.new(exception) }

  describe "#body" do
    it "includes the message in the body" do
      error.body[:error][:message].should == exception.message
    end

    it "includes the backtrace if it should be there" do
      error.stub(:expose_backtrace?).and_return(true)
      error.body[:error][:backtrace].should == exception.backtrace
    end

    it "includes the backtrace if it should be there" do
      error.stub(:expose_backtrace?).and_return(false)
      error.body[:backtrace].should be_nil
    end
  end

  describe "#render" do
    it "returns 500 status" do
      error.render[0].should == 500
    end

    it "returns json content type" do
      error.render[1].should == {"Content-Type" => "application/json"}
    end

    it "returns the JSONified body as the 2nd" do
      error.render[2].should == [MultiJson.dump(error.body)]
    end
  end

  describe "#expose_backtrace?" do
    it "returns whether Rails.env.production?" do
      result = stub
      Rails.env.stub(:production?).and_return(result)
      error.expose_backtrace?.should == result
    end
  end
end
