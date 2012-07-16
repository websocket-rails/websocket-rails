#require 'actionpack/action_dispatch/request'

module WebsocketRails
  class Dispatcher
    
    attr_reader :event_map, :connection_manager
    
    def initialize(connection_manager)
      @connection_manager = connection_manager
      @event_map = EventMap.new( self )
    end
  
    def receive_encoded(encoded_data,connection)
      event = Event.new_from_json( encoded_data, connection )
      dispatch( event )
    end

    def receive(event_name,data,connection)
      event = Event.new event_name, data, connection
      dispatch( event )
    end
    
    def dispatch(event)
      if event.is_channel?
        WebsocketRails[event.channel].trigger_event event
      else
        route event
      end
    end
    
    def send_message(event)
      event.connection.trigger event
    end
  
    def broadcast_message(event)
      connection_manager.connections.map do |connection|
        connection.trigger event
      end
    end

    private

    def route(event)
      actions = []
      event_map.routes_for event do |controller,method|
        actions << Fiber.new do
          begin
            controller.instance_variable_set(:@_event,event)
            controller.send :execute_observers, event.name if controller.respond_to?(:execute_observers)
            result = controller.send method if controller.respond_to?(method)
          rescue Exception => ex
            puts "Application Exception: #{ex.inspect}"
            event.success = false
            event.data = extract_exception_data ex
            event.trigger
          end
        end
      end
      execute actions
    end

    def execute(actions)
      actions.map do |action|
        EM.next_tick { action.resume }
      end
    end

    def extract_exception_data(ex)
      case ex
      when ActiveRecord::RecordInvalid
        {
          :record => ex.record.attributes,
          :errors => ex.record.errors,
          :full_messages => ex.record.errors.full_messages
        }
      else
        ex if ex.respond_to?(:to_json)
      end
    end

  end
end
