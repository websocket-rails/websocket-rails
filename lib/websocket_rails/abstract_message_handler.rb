module WebsocketRails
  class AbstractMessageHandler

    class << self
      attr_reader :handlers
    end

    def self.register_handler(handler)
      @handlers ||= []
      @handlers << handler
    end

    def self.handler_for_protocol(protocol)
      handlers.detect { |handler| handler.accepts?(protocol) }
    end

    def self.inherited(handler)
      register_handler handler
    end

    def self.accepts?(protocol)
      raise NotImplementedError, "Implement in the protocol specific handler class"
    end

    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def on_open(data = nil)
      raise NotImplementedError, "Implement in the protocol specific handler class"
    end

    def on_message(data = nil)
      raise NotImplementedError, "Implement in the protocol specific handler class"
    end

    def on_close(data = nil)
      raise NotImplementedError, "Implement in the protocol specific handler class"
    end

    def on_error(data = nil)
      raise NotImplementedError, "Implement in the protocol specific handler class"
    end

  end
end
