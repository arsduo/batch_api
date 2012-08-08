require 'spec_helper'

describe "Batch API Endpoint", :type => :routing do

  it "draws the route using default values" do
    expect(BatchApi::RoutingHelper::DEFAULT_VERB => BatchApi::RoutingHelper::DEFAULT_ENDPOINT).to route_to("batch_api/batch#batch")
  end

  it "draws the route using custom values" do
    expect("report" => "/foo/bar").to route_to("batch_api/batch#batch")
  end
end

