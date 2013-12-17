require 'faye/websocket'
require 'rack'
require 'thin'

Faye::WebSocket.load_adapter('thin')

module WebsocketRails

  def self.connection_manager
    @connection_manager ||= ConnectionManager.new
  end

  # The +ConnectionManager+ class implements the core Rack application that handles
  # incoming WebSocket connections.
  class ConnectionManager

    include Logging
    delegate :sync, to: Synchronization

    BadRequestResponse = [400,{'Content-Type' => 'text/plain'},['invalid']].freeze
    ExceptionResponse  = [500,{'Content-Type' => 'text/plain'},['exception']].freeze

    # Contains a Hash of currently open connections.
    # @return [Hash]
    attr_reader :connections

    # Contains the {Dispatcher} instance for the active server.
    # @return [Dispatcher]
    attr_reader :dispatcher

    # Contains the {Synchronization} instance for the active server.
    # @return [Synchronization]
    attr_reader :synchronization

    def initialize
      @connections = {}
      @dispatcher  = Dispatcher.new(self)
      @dispatcher.process_inbound

      if WebsocketRails.synchronize?
        EM.next_tick do
          Fiber.new {
            sync.synchronize!
            EM.add_shutdown_hook { sync.shutdown! }
          }.resume
        end
      end
    end

    def inspect
      "websocket_rails"
    end

    # Primary entry point for the Rack application
    def call(env)
      request = ActionDispatch::Request.new(env)

      response = open_connection(request)

      response
    rescue InvalidConnectionError => ex
      error "Invalid connection attempt: #{ex.message}"
      BadRequestResponse
    rescue Exception => ex
      error "Exception occurred while opening connection: #{ex.message}"
      ExceptionResponse
    end

    private

    def open_connection(request)
      raise InvalidConnectionError unless Connection.websocket?(request.env)

      connection = Connection.new(request, dispatcher)

      register_user_connection connection

      connections[connection.id.to_s] = connection

      info "Connection opened: #{connection}"
      connection.rack_response
    end

    def close_connection(connection)
      WebsocketRails.channel_manager.unsubscribe connection
      destroy_user_connection connection

      connections.delete connection.id.to_s

      info "Connection closed: #{connection}"
      connection = nil
    end
    public :close_connection

    def register_user_connection(connection)
      return unless connection.user_connection?
      WebsocketRails.users[connection.user_identifier] = connection
    end

    def destroy_user_connection(connection)
      return unless connection.user_connection?
      WebsocketRails.users.delete(connection)
    end

  end
end
