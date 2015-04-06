require 'spec_helper'

describe BatchApi::InternalMiddleware::ResponseFilter do
  let(:app) { double("app", call: result) }
  let(:surpressor) { BatchApi::InternalMiddleware::ResponseFilter.new(app) }
  let(:env) { {
    op: double("operation", options: {"silent" => true})
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
          expect(result.as_json).to eq({})
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

