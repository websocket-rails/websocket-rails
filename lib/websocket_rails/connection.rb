require "uuidtools"

module WebsocketRails
  class Connection

    include Logging

    def self.websocket?(env)
      Faye::WebSocket.websocket?(env)
    end

    attr_reader :id, :dispatcher, :queue, :env, :request, :data_store,
                :websocket, :message_handler

    delegate :supported_protocols, to: WebsocketRails
    delegate :on_open, :on_message, :on_close, :on_error, to: :message_handler

    def initialize(request, dispatcher)
      @id         = UUIDTools::UUID.random_create
      @env        = request.env.dup
      @request    = request
      @dispatcher = dispatcher
      @connected  = true
      @websocket  = Faye::WebSocket.new(request.env, supported_protocols, ping: 10)
      @data_store = DataStore::Connection.new(self)
      @delegate   = WebsocketRails::DelegationController.new
      @delegate.instance_variable_set(:@_env, request.env)
      @delegate.instance_variable_set(:@_request, request)

      puts "opening connection #{@websocket.protocol}"

      bind_message_handler
    rescue => ex
      raise InvalidConnectionError, ex.message
    end

    def enqueue(event)
      @queue << event
    end

    def trigger(event)
      send event.serialize
    end

    def flush
      message = []
      @queue.flush do |event|
        message << event.as_json
      end
      send message.to_json
    end

    def send_message(*args)
      @message_handler.send_message(*args)
    end

    def send(message)
      @websocket.send message
    end

    def close!
      @websocket.close
    end

    def close_connection
      @data_store.destroy!
      dispatcher.connection_manager.close_connection self
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

    def current_user_responds_to?(identifier)
      controller_delegate                            &&
      controller_delegate.respond_to?(:current_user) &&
      controller_delegate.current_user               &&
      controller_delegate.current_user.respond_to?(identifier)
    end

    def bind_message_handler
      handler_class = AbstractMessageHandler.handler_for_protocol(websocket.protocol)
      puts "#{AbstractMessageHandler.handlers}"
      @message_handler = handler_class.new(self)

      @websocket.onopen    = @message_handler.method(:on_open)
      @websocket.onmessage = @message_handler.method(:on_message)
      @websocket.onclose   = @message_handler.method(:on_close)
      @websocket.onerror   = @message_handler.method(:on_error)
    end

  end
end
