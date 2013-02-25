require 'faye/websocket'
require 'rack'
require 'thin'

module WebsocketRails
  # The +ConnectionManager+ class implements the core Rack application that handles
  # incoming WebSocket connections.
  class ConnectionManager

    include Logging

    SuccessfulResponse = [200,{'Content-Type' => 'text/plain'},['success']].freeze
    BadRequestResponse = [400,{'Content-Type' => 'text/plain'},['invalid']].freeze
    ExceptionResponse  = [500,{'Content-Type' => 'text/plain'},['exception']].freeze

    # Contains an Array of currently open connections.
    # @return [Array]
    attr_reader :connections

    # Contains the {Dispatcher} instance for the active server.
    # @return [Dispatcher]
    attr_reader :dispatcher

    # Contains the {Synchronization} instance for the active server.
    # @return [Synchronization]
    attr_reader :synchronization

    def initialize
      @connections = []
      @dispatcher  = Dispatcher.new(self)

      if WebsocketRails.synchronize?
        EM.next_tick do
          Fiber.new {
            Synchronization.synchronize!
            EM.add_shutdown_hook { Synchronization.shutdown! }
          }.resume
        end
      end
    end

    # Primary entry point for the Rack application
    def call(env)
      request = ActionDispatch::Request.new(env)

      if request.post?
        response = parse_incoming_event(request.params)
      else
        response = open_connection(request)
      end

      response
    rescue InvalidConnectionError
      BadRequestResponse
    end

    private

    def parse_incoming_event(params)
      connection = find_connection_by_id params["client_id"]
      connection.on_message params["data"]
      SuccessfulResponse
    end

    def find_connection_by_id(id)
      connections.detect { |connection| connection.id == id.to_i } || (raise InvalidConnectionError)
    end

    # Opens a persistent connection using the appropriate {ConnectionAdapter}. Stores
    # active connections in the {connections} array.
    def open_connection(request)
      connection = ConnectionAdapters.establish_connection( request, dispatcher )
      connections << connection
      log "Connection opened: #{connection}"
      connection.rack_response
    end

    def close_connection(connection)
      WebsocketRails.channel_manager.unsubscribe connection
      connections.delete connection
      log "Connection closed: #{connection}"
      connection = nil
    end
    public :close_connection

  end
end
