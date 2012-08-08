require 'spec_helper'
require 'batch_api/operation'

describe BatchApi::BatchController do
  describe "#batch" do
    it "creates batch ops for each operation using the request environment" do
      ops = 10.times.collect {|i| ({"operation" => i.to_s}) }
      ops.each do |o|
        BatchApi::Operation.should_receive(:new).with(o, request.env).and_return(stub(:execute => ""))
      end

      xhr :post, :batch, ops: ops
    end

    it "returns the resultof the batch operation's execution as JSON and in order" do
      ops = 10.times.collect {|i| {"operation" => i.to_s} }
      ops.each do |o|
        BatchApi::Operation.should_receive(:new).and_return(stub(:execute => o["operation"]))
      end

      xhr :post, :batch, ops: ops
      json = JSON.parse(response.body)
      ops.each_with_index do |o, i|
        json[i].should == i.to_s
      end
    end
  end
end
