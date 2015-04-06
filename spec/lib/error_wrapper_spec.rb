require 'spec_helper'
require 'batch_api/error_wrapper'

describe BatchApi::ErrorWrapper do
  let(:exception) {
    StandardError.new(Faker::Lorem.words(3)).tap do |e|
      e.set_backtrace(Kernel.caller)
    end
  }

  let(:error) { BatchApi::ErrorWrapper.new(exception) }

  describe "#body" do
    it "includes the message in the body" do
      expect(error.body[:error][:message]).to eq(exception.message)
    end

    it "includes the backtrace if it should be there" do
      allow(error).to receive(:expose_backtrace?).and_return(true)
      expect(error.body[:error][:backtrace]).to eq(exception.backtrace)
    end

    it "includes the backtrace if it should be there" do
      allow(error).to receive(:expose_backtrace?).and_return(false)
      expect(error.body[:backtrace]).to be_nil
    end
  end

  describe "#render" do
    it "returns the appropriate status" do
      status = double
      allow(error).to receive(:status_code).and_return(status)
      expect(error.render[0]).to eq(status)
    end

    it "returns appropriate content type" do
      ctype = double
      allow(BatchApi::RackMiddleware).to receive(:content_type).and_return(ctype)
      expect(error.render[1]).to eq(ctype)
    end

    it "returns the JSONified body as the 2nd" do
      expect(error.render[2]).to eq([MultiJson.dump(error.body)])
    end
  end

  describe "#status_code" do
    it "returns 500 by default" do
      expect(error.status_code).to eq(500)
    end

    it "returns another status code if the error supports that" do
      err = StandardError.new
      code = double
      allow(err).to receive(:status_code).and_return(code)
      expect(BatchApi::ErrorWrapper.new(err).status_code).to eq(code)
    end
  end

  describe ".expose_backtrace?" do
    it "returns false if Rails.env.production?" do
      allow(Rails).to receive(:env).and_return(double(test?: false, production?: true, development?: false))
      expect(BatchApi::ErrorWrapper.expose_backtrace?).to be_falsey
      allow(Rails.env).to receive(:production?).and_return(false)
      expect(BatchApi::ErrorWrapper.expose_backtrace?).to be_truthy
    end
  end
end
