module WebsocketRails
  module ConnectionAdapters
    
    attr_reader :adapters
    module_function :adapters
    
    def self.register(adapter)
      @adapters ||= []
      @adapters.unshift adapter
    end
    
    def self.establish_connection(env,dispatcher)
      adapter = adapters.detect { |a| a.accepts?( env ) } || (raise InvalidConnectionError)
      adapter.new env, dispatcher
    end
    
    class Base

      def self.accepts?(env)
        false
      end
      
      def self.inherited(adapter)
        ConnectionAdapters.register adapter
      end
      
      attr_reader :dispatcher, :queue

      def initialize(env,dispatcher)
        @env        = env
        @queue      = EventQueue.new
        @dispatcher = dispatcher
      end

      def on_open(data=nil)
        event = Event.new_on_open( self, data )
        dispatch event
        trigger event
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

      def enqueue(event)
        @queue << event
      end

      def trigger(event)
        enqueue event
        unless flush_scheduled
          EM.next_tick { flush; flush_scheduled = false }
          flush_scheduled = true
        end
      end

      def flush
        message = "["
        @queue.flush do |event|
          message << event.serialize
          message << "," unless event == @queue.last
        end
        message << "]"
        send message
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

      def flush_scheduled
        @flush_scheduled
      end

      def flush_scheduled=(value)
        @flush_scheduled = value
      end
    end
    
  end
end
