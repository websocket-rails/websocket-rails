module WebsocketRails
  # Provides a DSL for mapping client events to controller actions.
  #
  # == Example events.rb file
  #   # located in config/initializers/events.rb
  #   WebsocketRails::EventMap.describe do
  #     subscribe :client_connected, to: ChatController, with_method: :client_connected
  #   end
  #
  # A single event can be mapped to any number of controller actions.
  #
  #   subscribe :new_message, :to => ChatController, :with_method => :rebroadcast_message
  #   subscribe :new_message, :to => LogController, :with_method => :log_message
  #
  # Events can be nested underneath namesapces.
  #
  #   namespace :product do
  #     subscribe :new, :to => ProductController, :with_method => :new
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

      # Stores controller/action pairs for events subscribed under
      # this namespace.
      def store(event_name,options)
        klass  = options[:to] || raise("Must specify a class for to: option in event route")
        action = options[:with_method] || raise("Must specify a method for with_method: option in event route")
        create_controller_instance_for klass if controllers[klass].nil?
        actions[event_name] << [klass,action]
      end

      # Iterates through the namespace tree and yields all
      # controller/action pairs stored for the target event.
      def routes_for(event,event_namespace=nil,&block)

        # Grab the first level namespace from the namespace array
        # and remove it from the copy.
        event_namespace = copy_event_namespace( event, event_namespace ) || return
        namespace       = event_namespace.shift

        # If the namespace matches the current namespace and we are
        # at the last namespace level, yield any controller/action
        # pairs for this event.
        #
        # If the namespace does not match, search the list of child
        # namespaces stored at this level for a match and delegate
        # to it's #routes_for method, passing along the current
        # copy of the event's namespace array.
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

      def copy_event_namespace(event,namespace=nil)
        namespace = event.namespace.dup if namespace.nil?
        namespace
      end
      
    end
    
  end
end
