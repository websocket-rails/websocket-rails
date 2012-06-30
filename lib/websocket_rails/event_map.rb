module WebsocketRails
  # Provides a DSL for mapping client events to controller actions. A single event can be mapped to any
  # number of controllers and actions. You can define your event routes by creating an +events.rb+ file in
  # your application's +initializers+ directory. The DSL currently consists of two methods. The first is
  # {#subscribe}, which takes a symbolized event name as the first argument, and a Hash with the controller 
  # and method name as the second argument. The second is {#namespace} which allows you to scope your
  # actions within particular namespaces. The {#namespace} method takes a symbol representing the name
  # of the namespace, and a block which contains the actions you wish to subscribe within that namespace.
  # When an event is dispatched to the client, the namespace will be attached to the front of the event
  # name separated by a period. The `new` event listed in the example below under the `product` namespace
  # would arrive on the client as `product.new`. Similarly, incoming events in the `namespace.event_name`
  # format will be properly dispatched to the `event_name` under the correct `namespace`. Namespaces can
  # be nested.
  #
  # == Example events.rb file
  #   # located in config/initializers/events.rb
  #   WebsocketRails::EventMap.describe do
  #     subscribe :client_connected, to: ChatController, with_method: :client_connected
  #     subscribe :new_user, :to => ChatController, :with_method => :new_user
  #
  #     namespace :product do
  #       subscribe :new, :to => ProductController, :with_method => :new
  #     end
  #   end
  class EventMap
    
    def self.describe(&block)
      WebsocketRails.route_block = block
    end

    attr_reader :namespace
    
    def initialize(dispatcher)
      @dispatcher = dispatcher
      @namespace  = DSL.new(dispatcher).evaluate WebsocketRails.route_block
      @namespace  = DSL.new(dispatcher,@namespace).evaluate InternalEvents.events
    end
    
    def routes_for(event, &block)
      @namespace.routes_for event, &block
    end
    
    # Provides the DSL methods available to the Event routes file
    class DSL

      def initialize(dispatcher,namespace=nil)
        if namespace
          @namespace = namespace
        else
          @namespace = Namespace.new :global, dispatcher
        end
      end
      
      def evaluate(route_block)
        instance_eval &route_block unless route_block.nil?
        @namespace
      end

      def subscribe(event_name,options)
        @namespace.store event_name, options
      end

      def namespace(new_namespace,&block)
        @namespace = @namespace.find_or_create new_namespace
        instance_eval &block if block.present?
        @namespace = @namespace.parent
      end

    end

    # Stores route map for nested namespaces 
    class Namespace
      
      attr_reader :name, :controllers, :actions, :namespaces, :parent

      def initialize(name,dispatcher,parent=nil)
        @name        = name
        @parent      = parent
        @dispatcher  = dispatcher
        @actions     = Hash.new {|h,k| h[k] = Array.new}
        @controllers = Hash.new
        @namespaces  = Hash.new
      end

      def find_or_create(namespace)
        unless child = namespaces[namespace]
          child = Namespace.new namespace, @dispatcher, self
          namespaces[namespace] = child
        end
        child
      end

      def store(event_name,options)
        klass  = options[:to] || raise("Must specify a class for to: option in event route")
        action = options[:with_method] || raise("Must specify a method for with_method: option in event route")
        create_controller_instance_for klass if controllers[klass].nil?
        actions[event_name] << [klass,action]
      end

      def routes_for(event,event_namespace=nil,&block)
        event_namespace = event.namespace.dup if event_namespace.nil?
        return if event_namespace.nil?
        namespace = event_namespace.shift
        if namespace == @name and event_namespace.empty?
          actions[event.name].each do |klass,action|
            controller = controllers[klass]
            block.call controller, action
          end
        else
          child_namespace = event_namespace.first
          child = namespaces[child_namespace]
          child.routes_for event, event_namespace, &block unless child.nil?
        end
      end

      private

      def create_controller_instance_for(klass)
        controller = klass.new
        controllers[klass] = controller
        controller.instance_variable_set(:@_dispatcher,@dispatcher)
        controller.send :initialize_session if controller.respond_to?(:initialize_session)
      end
      
    end
    
  end
end
