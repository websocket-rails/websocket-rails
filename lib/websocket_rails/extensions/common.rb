require 'websocket_rails/extensions/websocket_rack'
module WebsocketRails
  module Extensions
    module Common
      def self.apply!
        Rack::WebSocket::Handler::Thin.send(:include,RackWebsocketExtensions)
      end
    end
  end
end
    