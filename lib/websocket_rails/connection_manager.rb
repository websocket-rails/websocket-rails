require 'faye/websocket'
require 'rack'
require 'thin'

module WebsocketRails
  class ConnectionManager
    
    attr_accessor :connections
    
    def initialize
      @connections = []
      @dispatcher = Dispatcher.new( self )
    end
    
    def call(env)
      return invalid_connection_attempt unless Faye::WebSocket.websocket?( env )
      connection = Faye::WebSocket.new( env )
      
      puts "Client #{connection} connected\n"
      @dispatcher.dispatch( 'client_connected', {}, connection )
      
      
      connection.onmessage = lambda do |event|
        @dispatcher.receive( event.data, connection )
      end
      
      connection.onerror = lambda do |event|
        @dispatcher.dispatch( 'client_error', {}, connection )
        connection.onclose
      end
      
      connection.onclose = lambda do |event|
        @dispatcher.dispatch( 'client_disconnected', {}, connection )
        connections.delete( connection )
        
        puts "Client #{connection} disconnected\n"
        connection = nil
      end
      
      connections << connection
      connection.rack_response
    end
  
  
    def broadcast_message(message)
      @connections.map do |connection|
        connection.send message
      end
    end
    
    private
    
    def invalid_connection_attempt
      [400,{'Content-Type' => 'text/plain'}, ['Connection was not a valid WebSocket connection']]
    end
    
  end
end