module WebsocketRails
  
  class Engine < Rails::Engine
    initialize "websocket_rails.load_app_instance_data" do |app|
      WebsocketRails.setup do |config|
        config.app_root = app.root
      end
    end
    
    initialize "websocket_rails.load_static_assets" do |app|
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end    
  end
end