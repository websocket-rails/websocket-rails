module WebsocketRails
  module ConnectionAdapters
    class WebSocket < Base
      
      def self.accepts?(env)
        Faye::WebSocket.websocket?( env )
      end
      
      def initialize(env,dispatcher)
        super
        @connection = Faye::WebSocket.new( env )
        @connection.onmessage = method(:on_message)
        @connection.onerror   = method(:on_error)
        @connection.onclose   = method(:on_close)
        on_open
      end
      
      def send(message)
        @connection.send message
      end
      
    end
  end
end
