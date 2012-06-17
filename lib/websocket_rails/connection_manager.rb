require 'faye/websocket'
require 'rack'
require 'thin'

module WebsocketRails
  class InvalidConnection < StandardError; end
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
    
    # Primary entry point for the Rack application
    def call(env)      
      request = Rack::Request.new( env )
      if request.post?
        response = parse_incoming_event( request.params )
      else
        response = open_connection( env )
      end
      response
    end
    
    # Used to broadcast a message to all connected clients. This method should never
    # be called directly. Instead, users should use {BaseController#broadcast_message}
    # and {BaseController#send_message} in their applications.
    def broadcast_message(message)
      connections.map do |connection|
        connection.send message
      end
    end
    
    private

    def parse_incoming_event(params)
      connection = find_connection_by_id params["client_id"]
      connection.on_message params["data"]
      [200,{'Content-Type' => 'text/plain'},['success']]
    rescue InvalidConnection
      [400,{'Content-Type' => 'text/plain'},['invalid connection']]
    end

    def find_connection_by_id(id)
      connections.detect { |connection| connection.id == id.to_i } || (raise InvalidConnection)
    end
    
    # Opens a persistent connection using the appropriate {ConnectionAdapter}. Stores
    # active connections in the {connections} array.
    def open_connection(env)
      connection = ConnectionAdapters.establish_connection( env, dispatcher )
      return invalid_connection_attempt unless connection
      
      puts "Client #{connection} connected\n"
      
      connections << connection
      connection.rack_response
    end

    def close_connection(connection)
      connections.delete connection
      puts "Client #{connection} disconnected\n"
      connection = nil
    end
    public :close_connection

    def invalid_connection_attempt
      [400,{'Content-Type' => 'text/plain'}, ['Connection was not a valid WebSocket connection']]
    end
    
  end
end
