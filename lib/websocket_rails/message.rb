module WebsocketRails
  # This is an abstract class that represents
  # an inbound or outbound message on the socket.
  #
  # The methods defined here are the bare minimum
  # interface necessary for compliance with Synchronization
  # and Dispatching.
  class Message

    extend Logging

    # Receives the raw message from the socket and the
    # {Connection} instance from which the message was
    # sent.
    #
    # It should return a new deserialized instance of {Message}
    def self.deserialize(raw_message, connection)
      raise NotImplementedError
    end

    include Logging

    # The message type is used to determine which Dispatcher
    # will process the message. The type can be static or
    # dynamic if a message should be handled by a different
    # Dispatcher depending on it's state.
    def type
      raise NotImplementedError
    end

    # The protocol that this message's connection has negotiated.
    # This will be used when searching for protocol specific
    # routes added through the event router.
    def protocol
      raise NotImplementedError
    end

    # Returns a protocol compliant serialized form of the message
    # that will be sent to the client through the socket.
    def serialize
      raise NotImplementedError
    end

  end
end
