require 'spec_helper'

describe "Batch API Endpoint", :type => :routing do

  it "draws the route appropriately" do
    expect(BatchApi.config.verb => BatchApi.config.endpoint).to route_to("batch#batch")
  end
end

