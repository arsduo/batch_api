require 'spec_helper'
require 'batch_api/operation'

describe BatchApi::BatchController do
  describe "#batch" do
    it "returns the result of the batch operation's execution as JSON and in order" do
      env = request.env
      ops = 10.times.collect {|i| {"operation" => i.to_s} }
      params = {ops: ops, sequential: true}
      result = ops.map(&:to_s)

      processor = stub("processor", :execute! => result)
      BatchApi::Processor.should_receive(:new).with(ops, request.env, hash_including(params)).and_return(processor)

      xhr :post, :batch, params
      json = JSON.parse(response.body)
      ops.each_with_index do |o, i|
        json[i].should == ops[i].to_s
      end
    end
  end
end
