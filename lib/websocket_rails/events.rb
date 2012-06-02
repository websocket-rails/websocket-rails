module WebsocketRails
  # Provides a DSL for mapping client events to controller actions. A single event can be mapped to any
  # number of controllers and actions. You can define your event routes by creating an +events.rb+ file in
  # your application's +initializers+ directory. The DSL currently consists of a single method, {#subscribe},
  # which takes a symbolized event name as the first argument, and a Hash with the controller and method
  # name as the second argument.
  #
  # == Example events.rb file
  #   # located in config/initializers/events.rb
  #   WebsocketRails::Events.describe_events do
  #     subscribe :client_connected, to: ChatController, with_method: :client_connected
  #     subscribe :new_user, to: ChatController, with_method: :new_user
  #   end
  class Events
    
    def self.describe_events(&block)
      WebsocketRails.route_block = block
    end
    
    attr_reader :classes, :events
    
    def initialize(dispatcher)
      @dispatcher = dispatcher
      evaluate( WebsocketRails.route_block ) if WebsocketRails.route_block
    end
    
    def routes_for(event,&block)
      @events[event].each do |klass,method|
        controller = @classes[klass]
        block.call( controller, method )
      end
    end
    
    def subscribe(event_name,options)
      klass  = options[:to] || raise("Must specify a class for to: option in event route")
      method = options[:with_method] || raise("Must specify a method for with_method: option in event route")
      controller = klass.new
      if @classes[klass].nil?
        @classes[klass] = controller
        controller.instance_variable_set(:@_dispatcher,@dispatcher)
        controller.send :initialize_session if controller.respond_to?(:initialize_session)
      end
      @events[event_name] << [klass,method]
    end    
    
    def evaluate(block)
      @events  = Hash.new {|h,k| h[k] = Array.new}
      @classes = Hash.new
      instance_eval &block
    end
    
  end
end