module WebsocketRails

  class Engine < Rails::Engine

    config.autoload_paths += [File.expand_path("../../lib", __FILE__)]
    config.app_middleware.insert_before(ActionDispatch::BestStandardsSupport, WebsocketRails::Stager)
    config.app_middleware.insert_after(WebsocketRails::Stager, WebsocketRails::Redis::RedisSubscriber)
    
    paths["app"] << "lib/rails/app"
    paths["app/controllers"] << "lib/rails/app/controllers"
    paths["config/routes"] << "lib/rails/config/routes.rb"
    
    initializer "overiding router" do |app|
      ws_route = File.expand_path File.dirname(__FILE__)+'/../rails/config/routes.rb';
      app.routes_reloader.paths.delete_if{ |path| path.include?(ws_route) }
      app.routes_reloader.paths.prepend(ws_route)
    end
    
  end
end
