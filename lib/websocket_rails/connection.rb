require "uuidtools"

module WebsocketRails
  class Connection

    include Logging

    def self.accepts?(env)
      Faye::Websocket.websocket?(env)
    end

    attr_reader :id, :dispatcher, :queue, :env, :request, :data_store, :websocket

    def initialize(request, dispatcher)
      @id         = UUIDTools::UUID.random_create
      @env        = request.env.dup
      @request    = request
      @dispatcher = dispatcher
      @connected  = true
      @websocket  = Faye::WebSocket.new(request.env, [], ping: 10)
      @data_store = DataStore::Connection.new(self)
      @delegate   = WebsocketRails::DelegationController.new
      @delegate.instance_variable_set(:@_env, request.env)
      @delegate.instance_variable_set(:@_request, request)

      bind_message_handler

      EM.next_tick do
        on_open
      end
    rescue => ex
      raise InvalidConnectionError, ex.message
    end

    def on_open(data=nil)
      event = Event.new_on_open( self, data )
      dispatch event
      trigger event
    end

    def on_message(message)
      encoded_message = message.respond_to?(:data) ? message.data : message
      event = Event.new_from_json( encoded_message, self )
      dispatch event
    end

    def on_close(data=nil)
      dispatch Event.new_on_close( self, data )
      close_connection
    end

    def on_error(data=nil)
      event = Event.new_on_error( self, data )
      dispatch event
      on_close event.data
    end

    def enqueue(event)
      @queue << event
    end

    def trigger(event)
      send "[#{event.serialize}]"
    end

    def flush
      message = []
      @queue.flush do |event|
        message << event.as_json
      end
      send message.to_json
    end

    def send_message(event_name, data = {}, options = {})
      options.merge! :user_id => user_identifier, :connection => self
      options[:data] = data

      event = Event.new(event_name, options)
      event.trigger
    end

    def send(message)
      @websocket.send message
    end

    def close!
      @websocket.close
    end

    def rack_response
      [ -1, {}, [] ]
    end

    def controller_delegate
      @delegate
    end

    def connected?
      true & @connected
    end

    def inspect
      "#<Connection::#{id}>"
    end

    def to_s
      inspect
    end

    def user_connection?
      not user_identifier.nil?
    end

    def user
      return unless user_connection?
      controller_delegate.current_user
    end

    def user_identifier
      @user_identifier ||= begin
        identifier = WebsocketRails.config.user_identifier

        return unless current_user_responds_to?(identifier)

        controller_delegate.current_user.send(identifier)
       end
    end

    private

    def dispatch(event)
      dispatcher.dispatch event
    end

    def connection_manager
      dispatcher.connection_manager
    end

    def close_connection
      @data_store.destroy!
      dispatcher.connection_manager.close_connection self
    end

    def current_user_responds_to?(identifier)
      controller_delegate                            &&
      controller_delegate.respond_to?(:current_user) &&
      controller_delegate.current_user               &&
      controller_delegate.current_user.respond_to?(identifier)
    end

    def bind_message_handler
      @websocket.onmessage = method(:on_message)
      @websocket.onclose   = method(:on_close)
      @websocket.onerror   = method(:on_error)
    end

  end
end
