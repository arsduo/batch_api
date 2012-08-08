# CURRENT FILE :: lib/team_page/engine.rb
module BatchApi
  class Engine < Rails::Engine
    initializer "batch_api.add_routing_helper" do |app|
      ActionDispatch::Routing::Mapper.send(:include, BatchApi::RoutingHelper)
    end
  end
end
