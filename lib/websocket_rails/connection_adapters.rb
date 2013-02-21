module WebsocketRails
  module ConnectionAdapters

    attr_reader :adapters
    module_function :adapters

    def self.register(adapter)
      @adapters ||= []
      @adapters.unshift adapter
    end

    def self.establish_connection(request,dispatcher)
      adapter = adapters.detect { |a| a.accepts?( request.env ) } || (raise InvalidConnectionError)
      adapter.new request, dispatcher
    end

    class Base

      include Logging

      def self.accepts?(env)
        false
      end

      def self.inherited(adapter)
        ConnectionAdapters.register adapter
      end

      attr_reader :dispatcher, :queue, :env, :request, :data_store

      def initialize(request, dispatcher)
        @env        = request.env.dup
        @request    = request
        @dispatcher = dispatcher
        @connected  = true
        @queue      = EventQueue.new
        @data_store = DataStore::Connection.new(self)
        @delegate   = WebsocketRails::DelegationController.new
        @delegate.instance_variable_set(:@_env,request.env)
        @delegate.instance_variable_set(:@_request,request)
        start_ping_timer
      end

      def on_open(data=nil)
        event = Event.new_on_open( self, data )
        dispatch event
        trigger event
      end

      def on_message(encoded_data)
        event = Event.new_from_json( encoded_data, self )
        dispatch event
      end

      def on_close(data=nil)
        @ping_timer.cancel
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

      attr_accessor :flush_scheduled

      def trigger(event)
        # Uncomment when implementing history queueing with redis
        #enqueue event
        #unless flush_scheduled
        #  EM.next_tick { flush; flush_scheduled = false }
        #  flush_scheduled = true
        #end
        send "[#{event.serialize}]"
      end

      def flush
        count = 1
        message = "["
        @queue.flush do |event|
          message << event.serialize
          message << "," unless count == @queue.size
          count += 1
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

      def controller_delegate
        @delegate
      end

      private

      def dispatch(event)
        dispatcher.dispatch( event )
      end

      def close_connection
        @data_store.destroy!
        dispatcher.connection_manager.close_connection self
      end

      attr_accessor :pong
      public :pong, :pong=

      def start_ping_timer
        @pong = true
        @ping_timer = EM::PeriodicTimer.new(10) do
          debug "ping"
          if pong == true
            self.pong = false
            ping = Event.new_on_ping self
            trigger ping
          else
            @ping_timer.cancel
            on_error
          end
        end
      end

    end

  end
end
