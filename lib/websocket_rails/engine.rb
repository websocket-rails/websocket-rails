require 'faye/websocket'

module WebsocketRails

  class Engine < Rails::Engine

    config.autoload_paths += [File.expand_path("../../lib", __FILE__)]

    paths["app"] << "lib/rails/app"
    paths["app/controllers"] << "lib/rails/app/controllers"

    if ::Rails.version >= '4.0.0'
      paths["config/routes.rb"]   << "lib/rails/config/routes.rb"
    else
      paths["config/routes"]   << "lib/rails/config/routes.rb"
    end

    initializer 'websocket_rails.load_event_routes', :before => :preload_frameworks do |app|
      Faye::WebSocket.load_adapter('thin') if defined?(Thin)
      load "#{Rails.root}/config/events.rb" if File.exists?("#{Rails.root}/config/events.rb")
    end

    rake_tasks do
      require 'websocket-rails'
      load 'rails/tasks/websocket_rails.tasks'
    end

  end
end
