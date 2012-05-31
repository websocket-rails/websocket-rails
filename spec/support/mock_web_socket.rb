module WebsocketRails
  
  class MockWebSocket
    attr_writer :onmessage, :onerror, :onclose
    
    def onmessage(event=nil)
      @onmessage.call(event)
    end
    
    def onerror(event=nil)
      @onerror.call(event)
    end
    
    def onclose(event=nil)
      @onclose.call(event)
    end
    
    def rack_response
      [ -1, {}, [] ]
    end
    
    def send(*args)
      true
    end    
  end
  
end