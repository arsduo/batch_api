require 'spec_helper'

describe "Rails hooks" do
  context "add_routing_helper" do
    it "makes the routing helpers available when routing" do
      ActionDispatch::Routing::Mapper.included_modules.should include(BatchApi::RoutingHelper)
    end
  end
end
