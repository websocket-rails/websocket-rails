module WebsocketRails
  module ConnectionAdapters
    class WebSocket < Base
      
      extend Forwardable
      
      def self.accepts?(env)
        ::Faye::WebSocket.websocket?( env )
      end
      
      def self.delegated_methods
        setter_methods = ADAPTER_EVENTS.map {|e| "#{e}=".to_sym }
        setter_methods + ADAPTER_EVENTS
      end
      def_delegators :@connection, *delegated_methods
      
      def initialize(env)
        super
        @connection = ::Faye::WebSocket.new( env )
      end
      
      def send(message)
        @connection.send message
      end
      
    end
  end
end