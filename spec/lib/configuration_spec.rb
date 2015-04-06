require 'spec_helper'

module BatchApi
  describe Configuration do
    let(:config) { Configuration.new }

    describe "options" do
      {
        verb: :post,
        endpoint: "/batch",
        limit: 50,
        batch_middleware: InternalMiddleware::DEFAULT_BATCH_MIDDLEWARE,
        operation_middleware: InternalMiddleware::DEFAULT_OPERATION_MIDDLEWARE
      }.each_pair do |option, default|
        opt, defa = option, default
        describe "##{opt}" do
          it "has an accessor for #{opt}" do
            stubby = double
            config.send("#{opt}=", stubby)
            expect(config.send(opt)).to eq(stubby)
          end

          it "defaults #{opt} to #{defa.inspect}" do
            expect(config.send(opt)).to eq(defa)
          end
        end
      end
    end
  end
end
