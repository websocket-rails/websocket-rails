require 'rails'

module WebsocketRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      desc "Create the events.rb initializer and require the JS client in the application.js manifest."

      class_option :manifest, :type => :string, :aliases => "-m", :default => 'application.js',
                   :desc => "Javascript manifest file to modify (or create)"

      def create_events_initializer_file
        template 'events.rb', File.join('config', 'events.rb')
        template 'websocket_rails.rb', File.join('config', 'initializers', 'websocket_rails.rb')
      end

      def inject_websocket_rails_client
        manifest = options[:manifest]
        js_path  = "app/assets/javascripts"

        create_file("#{js_path}/#{manifest}") unless File.exists?("#{js_path}/#{manifest}")

        append_to_file "#{js_path}/#{manifest}" do
          out = ""
          out << "//= require websocket_rails/main"
          out << "\n"
          out << "\n"
        end
      end
    end
  end
end
