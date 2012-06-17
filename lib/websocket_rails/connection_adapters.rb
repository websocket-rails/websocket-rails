module WebsocketRails
  module ConnectionAdapters
    
    attr_reader :adapters
    module_function :adapters
    
    def self.register_adapter(adapter)
      @adapters ||= []
      @adapters.unshift adapter
    end
    
    def self.establish_connection(env,dispatcher)
      adapter = adapters.detect { |a| a.accepts?( env ) } || return
      adapter.new( env, dispatcher )
    end
    
    class Base
      
      def self.inherited(adapter)
        ConnectionAdapters.register_adapter( adapter )
      end
      
      attr_accessor :dispatcher

      def initialize(env,dispatcher)
        @env = env
        @dispatcher = dispatcher
      end

      def on_open(data=nil)
        event = Event.new_on_open( self, data )
        dispatch event
        send event.serialize
      end

      def on_message(encoded_data)
        dispatch Event.new_from_json( encoded_data, self )
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
      
      def send(message)
        raise NotImplementedError, "Override this method in the connection specific adapter class"
      end
      
      def rack_response
        [ -1, {}, [] ]
      end
      
      def id
        object_id.to_i
      end

      private

      def dispatch(event)
        dispatcher.dispatch( event )
      end

      def close_connection
        dispatcher.connection_manager.close_connection self
      end
    end
    
  end
end
