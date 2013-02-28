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

    rake_tasks do
      require 'websocket-rails'
      load 'rails/tasks/websocket_rails.tasks'
    end

  end
end
