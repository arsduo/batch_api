require 'spec_helper'
require 'batch_api/errors/base'

describe BatchApi::Errors::Base do
  let(:exception) {
    StandardError.new(Faker::Lorem.words(3)).tap do |e|
      e.set_backtrace(Kernel.caller)
    end
  }

  let(:error) { BatchApi::Errors::Base.new(exception) }

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
    it "returns the appropriate status" do
      status = stub
      error.stub(:status_code).and_return(status)
      error.render[0].should == status
    end

    it "returns appropriate content type" do
      ctype = stub
      BatchApi::Middleware.stub(:content_type).and_return(ctype)
      error.render[1].should == ctype
    end

    it "returns the JSONified body as the 2nd" do
      error.render[2].should == [MultiJson.dump(error.body)]
    end
  end

  describe "#status_code" do
    it "returns 500" do
      error.status_code.should == 500
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
