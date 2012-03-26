module WebsocketRails
  class BaseController
    def initialize
      @data_store = DataStore.new(self)
    end
    
    def client_id
      @_message.first
    end

    def message
      @_message.last
    end

    def send_message(event,message)
      @_dispatcher.send_message event.to_s, [client_id,message]
    end

    def broadcast_message(event,message)
      @_dispatcher.broadcast_message event.to_s, message
    end
    
    def data_store
      @data_store
    end  
  end
end