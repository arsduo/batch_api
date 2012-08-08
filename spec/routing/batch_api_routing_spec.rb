require 'spec_helper'

describe "Batch API Endpoint", :type => :routing do

  it "draws the route using default values" do
    expect(BatchApi::RoutingHelper::DEFAULT_VERB => BatchApi::RoutingHelper::DEFAULT_ENDPOINT).to route_to("batch#batch")
  end
end

