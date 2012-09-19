require 'spec_helper'

describe BatchApi::Configuration do
  let(:config) { BatchApi::Configuration.new }

  describe "options" do
    {
      verb: :post,
      endpoint: "/batch",
      limit: 50,
      decode_json_responses: true
    }.each_pair do |option, default|
      opt, defa = option, default
      describe "##{opt}" do
        it "has an accessor for #{opt}" do
          stubby = stub
          config.send("#{opt}=", stubby)
          config.send(opt).should == stubby
        end

        it "defaults #{opt} to #{defa.inspect}" do
          config.send(opt).should == defa
        end
      end
    end
  end
end
