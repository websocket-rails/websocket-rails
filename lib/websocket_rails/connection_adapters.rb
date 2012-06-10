module WebsocketRails
  module ConnectionAdapters
    
    attr_reader :adapters
    module_function :adapters
    
    def self.register_adapter(adapter)
      @adapters ||= []
      @adapters.unshift adapter
    end
    
    def self.establish_connection(env)
      adapter = adapters.detect { |a| a.accepts?( env ) } || return
      adapter.new( env )
    end
    
    class Base
      
      ADAPTER_EVENTS = [:onmessage, :onerror, :onclose]
      
      def self.inherited(adapter)
        ConnectionAdapters.register_adapter( adapter )
      end
      
      def initialize(env)
        @env = env
      end
      
      ADAPTER_EVENTS.each do |adapter_event|
        define_method "#{adapter_event}" do |event=nil|
          instance_variable_get( "@#{adapter_event}" ).call( event )
        end
        define_method "#{adapter_event}=" do |block=nil|
          instance_variable_set( "@#{adapter_event}", block )
        end
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
    end
    
  end
end
