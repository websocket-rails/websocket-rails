module WebsocketRails
  class MessageHandler < AbstractMessageHandler

    def self.accepts?(protocol)
      protocol.blank?
    end

    def on_open(message = nil)
      event = Event.new_on_open(connection, message)
      dispatch event
      trigger event
    end

    def on_message(message = nil)
      encoded_message = message.respond_to?(:data) ? message.data : message
      event = Event.deserialize( encoded_message, connection )
      dispatch event
    end

    def on_close(message = nil)
      dispatch Event.new_on_close(connection, message)
      connection.close_connection
    end

    def on_error(message = nil)
      event = Event.new_on_error(connection, message)
      dispatch event
      on_close event.data
    end

    def send_message(event_name, data = nil, options = {})
      options.merge! :user_id => connection.user_identifier, :connection => connection

      event = Event.new(event_name, data, options)
      connection.trigger event
    end

    private

    def dispatch(event)
      dispatcher.dispatch event
    end

    def trigger(event)
      connection.trigger event
    end

    def dispatcher
      connection.dispatcher
    end

  end
end
