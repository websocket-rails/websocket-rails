module WebsocketRails
  # Provides a DSL for mapping client events to controller actions. A single event can be mapped to any
  # number of controllers and actions. You can define your event routes by creating an +events.rb+ file in
  # your application's +initializers+ directory. The DSL currently consists of a single method, {#subscribe},
  # which takes a symbolized event name as the first argument, and a Hash with the controller and method
  # name as the second argument.
  #
  # == Example events.rb file
  #   # located in config/initializers/events.rb
  #   WebsocketRails::EventMap.describe do
  #     subscribe :client_connected, to: ChatController, with_method: :client_connected
  #     subscribe :new_user, to: ChatController, with_method: :new_user
  #
  #     namespace :email do
  #       subscribe :new_email, to: EmailController, with_method: :new_email
  #     end
  #   end
  class EventMap
    
    def self.describe(&block)
      WebsocketRails.route_block = block
    end
    
    attr_reader :classes, :events

    GLOBAL_NAMESPACE = :global

    attr_reader :global_namespace

    attr_reader :current_namespace
    
    def initialize(dispatcher)
      @dispatcher = dispatcher
      evaluate WebsocketRails.route_block if WebsocketRails.route_block
    end
    
    def routes_for(event, namespace = :global, &block)
      events[namespace][event].each do |klass,method|
        controller = @classes[klass]
        block.call controller, method
      end
    end
    
    def subscribe(event_name,options)
      klass  = options[:to] || raise("Must specify a class for to: option in event route")
      method = options[:with_method] || raise("Must specify a method for with_method: option in event route")
      if classes[klass].nil?
        controller     = klass.new
        classes[klass] = controller
        controller.instance_variable_set(:@_dispatcher,@dispatcher)
        controller.send :initialize_session if controller.respond_to?(:initialize_session)
      end
      events[current_namespace][event_name] << [klass,method]
    end

    def namespace(new_namespace,&block)
      @current_namespace = new_namespace
      instance_eval &block if block.present?
      @current_namespace = global_namespace
    end
    
    def evaluate(block)
      @events  = Hash.new { |hash,namespace| hash[namespace] = EventMap::Events.new }
      @classes = Hash.new
      @global_namespace  = GLOBAL_NAMESPACE
      @current_namespace = global_namespace
      instance_eval &block if block.present?
    end

    # Thin Hash wrapper for storing events underneath different namespaces.
    class Events

      def initialize
        @events = Hash.new {|h,k| h[k] = Array.new}
      end

      def [](k)
        @events[k]
      end

      def []=(k,v)
        @events[k] = v
      end

      def has_key?(k)
        @events.has_key? k
      end

    end
    
  end
end
