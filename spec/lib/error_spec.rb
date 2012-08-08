require 'spec_helper'
require 'batch_api/error'

describe BatchApi::Error do
  let(:error) {
    BatchApi::Error.new(StandardError.new(Faker::Lorem.words(3)).tap do |e|
      e.set_backtrace(Kernel.caller)
    end)
  }

  it "has a cookies attribute" do
    error.should respond_to(:cookies)
  end

end
