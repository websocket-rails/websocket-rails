require 'json'

module WebsocketRails
  class Dispatcher  
    def initialize(connection)
      puts "Initializing dispatcher\n"
      @connection = connection
      @events  = Hash.new {|h,k| h[k] = Array.new}
      @classes = Hash.new
      evaluate(@@event_routes) if @@event_routes
    end
  
    def receive(enc_message,env)
      message = JSON.parse( enc_message )
      event_name = message.first
      data = message.last
      data['received'] = Time.now.strftime("%I:%M:%p")
      dispatch( event_name, data, env )
    end
  
    def send_message(event_name,data)
      @connection.send_message encoded_message( event_name, data.last ), data.first
    end
  
    def broadcast_message(event_name,data)
      @connection.broadcast_message encoded_message( event_name, data )
    end
    
    def dispatch(event_name,data,env)
      puts "#{event_name} is handled by #{@events[event_name.to_sym].inspect}\n\n"
      Fiber.new {
        event_symbol = event_name.to_sym
        message = [env['websocket.client_id'],data]
        @events[event_symbol].each do |event|
          method  = event.last
          handler = event.first
          klass = @classes[handler]
          klass.instance_variable_set(:@_message,message)
          klass.send :execute_observers, event_symbol
          klass.send method if klass.respond_to?(method)
        end
      }.resume
    end
  
    def close_connection
      @connection.close_connection
    end
  
    def encoded_message(event_name,data)
      [event_name, data].to_json
    end
  
    def subscribe(event_name,options)
      klass = options[:to] || raise("Must specify a class for to: option in event route")
      method = options[:with_method] || raise("Must specify a method for with_method: option in event route")
      controller = klass.new
      if @classes[klass].nil?
        @classes[klass] = controller
        controller.instance_variable_set(:@_dispatcher,self)
        controller.send :initialize_session if controller.respond_to?(:initialize_session)
      end
      @events[event_name] << [klass,method]
    end
  
    def self.describe_events(&block)
      @@event_routes = block
    end
  
    def evaluate(block)
      instance_eval &block
    end
  end
end