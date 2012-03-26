require 'rack'
require 'rack/websocket'
require 'json'
module WebsocketRails
  class ConnectionManager < Rack::WebSocket::Application
    def initialize(*args)
      @dispatcher = Dispatcher.new(self)
      super
    end
  
    def on_open(env)
      puts "Client connected\n"
      @dispatcher.dispatch('client_connected',{},env)
    end
    
    def on_message(env, msg)
      @dispatcher.receive( msg, env )
    end
    
    def on_error(env, error)
      puts "Error occured: " + error.message
    end
    
    def on_close(env)
      close_connection(env['websocket.client_id'])
      @dispatcher.dispatch('client_disconnected',{},env)
      puts "Client disconnected\n"
    end
  
    def send_message(msg,uid)
      send_data msg, uid
    end
  
    def broadcast_message(msg)
      send_data_all msg
    end
  end
end