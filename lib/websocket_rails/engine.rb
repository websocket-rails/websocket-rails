module WebsocketRails
  
  class Engine < Rails::Engine
    initializer "websocket_rails.load_app_instance_data" do |app|
      paths['app/controllers'] = 'app/controllers'
      WebsocketRails.setup do |config|
        config.app_root = app.root
      end
      app.config.autoload_paths += [File.expand_path("../../lib", __FILE__)]
    end
  end
end
