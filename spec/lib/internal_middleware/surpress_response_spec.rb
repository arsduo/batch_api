require 'spec_helper'

describe BatchApi::InternalMiddleware::SurpressResponse do
  let(:app) { stub("app", call: result) }
  let(:surpressor) { BatchApi::InternalMiddleware::SurpressResponse.new(app) }
  let(:env) { {
    op: stub("operation", options: {"silent" => true})
  } }

  let(:result) {
    BatchApi::Response.new([
      200,
      {"Content-Type" => "application/json"},
      ["{}"]
    ])
  }

  describe "#call" do
    context "for results with silent" do
      context "for successful (200-299) results" do
        it "empties the response so its as_json is empty" do
          surpressor.call(env)
          result.as_json.should == {}
        end
      end

      context "for non-successful responses" do
        it "doesn't change anything else" do
          result.status = 301
          expect {
            surpressor.call(env)
          }.not_to change(result, :to_s)
        end
      end
    end

    context "for results without silent" do
      before :each do
        env[:op].options[:silent] = nil
      end

      context "for successful (200-299) results" do
        it "does nothing" do
          expect {
            surpressor.call(env)
          }.not_to change(result, :to_s)
        end
      end

      context "for non-successful responses" do
        it "doesn't change anything else" do
          result.status = 301
          expect {
            surpressor.call(env)
          }.not_to change(result, :to_s)
        end
      end
    end
  end
end

