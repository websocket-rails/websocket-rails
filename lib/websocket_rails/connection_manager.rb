require 'faye/websocket'
require 'rack'
require 'thin'

module WebsocketRails
  # The +ConnectionManager+ class implements the core Rack application that handles
  # incoming WebSocket connections.
  class ConnectionManager
    
    # Contains an Array of currently open Faye::WebSocket connections.
    # @return [Array]
    attr_reader :connections
    
    # Contains the {Dispatcher} instance for the active server.
    # @return [Dispatcher]
    attr_reader :dispatcher
    
    def initialize
      @connections = []
      @dispatcher = Dispatcher.new( self )
    end
    
    # Opens a new Faye::WebSocket connection using the Rack env Hash. New connections 
    # dispatch the 'client_connected' event through the {Dispatcher} and are then 
    # stored in the active {connections} Array. An Async response is returned to 
    # signify to the web server that the connection will remain opened. Invalid 
    # connections return an HTTP 400 Bad Request response to the client.
    def call(env)      
      request = Rack::Request.new( env )
      if request.post?
        response = parse_incoming_event( request.params )
      else
        response = open_persistent_connection( env )
      end
      response
    end
    
    # Used to broadcast a message to all connected clients. This method should never
    # be called directly. Instead, users should use {BaseController#broadcast_message}
    # and {BaseController#send_message} in their applications.
    def broadcast_message(message)
      @connections.map do |connection|
        connection.send message
      end
    end
    
    private

    def parse_incoming_event(params)
      connection = find_connection_by_id params["client_id"]
      data = params["data"]
      @dispatcher.receive( data, connection )
      [200,{'Content-Type' => 'text/plain'},['success']]
    end

    def find_connection_by_id(id)
      connections.detect { |connection| connection.object_id.to_i == id.to_i }
    end
    
    def open_persistent_connection(env)
      connection = ConnectionAdapters.establish_connection( env )
      return invalid_connection_attempt unless connection
      
      puts "Client #{connection} connected\n"
      @dispatcher.dispatch( 'client_connected', {}, connection )
      @dispatcher.send_message( connection.object_id.to_i, :welcome, {}, connection )
      
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

    def invalid_connection_attempt
      [400,{'Content-Type' => 'text/plain'}, ['Connection was not a valid WebSocket connection']]
    end
    
  end
end
