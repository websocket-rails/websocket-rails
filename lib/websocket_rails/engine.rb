module WebsocketRails
  
  class Engine < Rails::Engine
    initializer "websocket_rails.load_app_instance_data" do |app|
      WebsocketRails.setup do |config|
        config.app_root = app.root
      end
      app.config.autoload_paths += [File.expand_path("../../lib", __FILE__)]
    end
    
    initializer "websocket_rails.load_static_assets" do |app|
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end    
  end
end