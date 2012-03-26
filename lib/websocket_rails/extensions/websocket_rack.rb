module WebsocketRails
  module Extensions
    module RackWebsocketExtensions
      def self.included(base)
        base.class_eval do
          alias :call_legacy :call
          alias :call :new_call
          
          alias :send_data_legacy :send_data
          alias :send_data :new_send_data
          
          alias :close_websocket_legacy :close_websocket
          alias :close_websocket :new_close_websocket
        end
      end
      # Build request from Rack env
      @@connection_pool = {}
      def new_call(env)
        env['websocket.client_id'] ||= rand(100000)
        @env = env
        socket = env['async.connection']
        request = request_from_env(env)
        @connection = Rack::WebSocket::Handler::Base::Connection.new(self, socket, :debug => @options[:debug])
        @@connection_pool[env['websocket.client_id']] = @connection       
        puts "We have #{@@connection_pool.count} open connection(s)\n"
        @@connection_pool[env['websocket.client_id']].dispatch(request) ? async_response : failure_response
      end

      # Forward send_data to server
      def new_send_data(data,uid)
        if @@connection_pool[uid]
          @@connection_pool[uid].send( data )
        end
      end
    
      # Forward send_data to server
      def send_data_all(data)
        if @@connection_pool
          @@connection_pool.each do |k,connection|
            connection.send( data )
          end
        end
      end
    
      # Forward close_websocket to server
      def new_close_websocket
        close_connection(env['websocket.client_id'])
      end
    
      def close_connection(uid)
        @@connection_pool.delete_if {|k,v| k == uid}
      end
    end
  end
end