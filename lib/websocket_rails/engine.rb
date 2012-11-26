module WebsocketRails

  class Engine < Rails::Engine

    config.autoload_paths += [File.expand_path("../../lib", __FILE__)]

    paths["app"] << "lib/rails/app"
    paths["app/controllers"] << "lib/rails/app/controllers"
    paths["config/routes"]   << "lib/rails/config/routes.rb"

    rake_tasks do
      require 'websocket-rails'
      load 'rails/tasks/websocket_rails.tasks'
    end

  end
end
