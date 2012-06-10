require 'json'

module WebsocketRails
  class Dispatcher
    
    def self.describe_events(&block)
      raise "This method has been deprecated. Please use WebsocketRails::Events.describe_events instead."
    end
    
    attr_reader :events
    
    def initialize(connection_manager)
      @connection_manager = connection_manager
      @events = Events.new( self )
    end
  
    def receive(enc_message,connection)
      message = JSON.parse( enc_message )
      event_name = message.first
      data = message.last
      data['received'] = Time.now.strftime("%I:%M:%p")
      dispatch( event_name, data, connection )
    end
  
    def send_message(client_id,event_name,data,connection)
      connection.send encoded_message( client_id, event_name, data )
    end
  
    def broadcast_message(client_id,event_name,data)
      @connection_manager.broadcast_message encoded_message( client_id, event_name, data )
    end
    
    def dispatch(event_name,message,connection)
      Fiber.new {
        event_symbol = event_name.to_sym
        events.routes_for(event_symbol) do |controller,method|
          controller.instance_variable_set(:@_message,message)
          controller.instance_variable_set(:@_connection,connection)
          controller.send :execute_observers, event_symbol
          controller.send method if controller.respond_to?(method)
        end
      }.resume
    end
    
    def encoded_message(client_id,event_name,data)
      [client_id, event_name, data].to_json
    end
    
  end
end
