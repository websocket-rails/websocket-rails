require 'json'

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
      Fiber.new {
        event_map.routes_for(event.name) do |controller,method|
          controller.instance_variable_set(:@_message,event.data)
          controller.instance_variable_set(:@_connection,event.connection)
          controller.instance_variable_set(:@_event,event)
          controller.send :execute_observers, event.name if controller.respond_to?(:execute_observers)
          controller.send method if controller.respond_to?(method)
        end
      }.resume
    end
    
    def send_message(event)
      event.connection.send event.serialize
    end
  
    def broadcast_message(event)
      connection_manager.connections.map do |connection|
        connection.send event.serialize
      end
    end

  end
end
