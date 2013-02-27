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
      WebsocketRails.config.route_block = block
    end

    attr_reader :namespace

    def initialize(dispatcher)
      @dispatcher = dispatcher
      @namespace  = DSL.new(dispatcher).evaluate WebsocketRails.config.route_block
      @namespace  = DSL.new(dispatcher,@namespace).evaluate InternalEvents.events
    end

    def routes_for(event, &block)
      @namespace.routes_for event, &block
    end

    # Proxy the reload_controllers! method to the global namespace.
    def reload_controllers!
      @namespace.reload_controllers!
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

      def private_channel(channel)
        WebsocketRails[channel].make_private
      end

    end

    # Stores route map for nested namespaces
    class Namespace

      include Logging

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
        klass, action = TargetValidator.validate_target options
        actions[event_name] << [klass,action]
      end

      # Iterates through the namespace tree and yields all
      # controller/action pairs stored for the target event.
      def routes_for(event, event_namespace=nil, &block)

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
            block.call klass, action
          end
        else
          child_namespace = event_namespace.first
          child = namespaces[child_namespace]
          child.routes_for event, event_namespace, &block unless child.nil?
        end
      end

      private

      def copy_event_namespace(event, namespace=nil)
        namespace = event.namespace.dup if namespace.nil?
        namespace
      end

    end

  end

  class TargetValidator

    # Parses the target and extracts controller/action pair or raises an error if target is invalid
    def self.validate_target(target)
      case target
        when Hash
          validate_hash_target target
        when String
          validate_string_target target
      else
        raise('Must specify the event target either as a string product#new_product or as a Hash to: ProductController, with_method: :new_product')
      end
    end

  private

    # Parses the target as a Hash, expecting keys to: and with_method:
    def self.validate_hash_target(target)
      klass  = target[:to] || raise("Must specify a class for to: option in event route")
      action = target[:with_method] || raise("Must specify a method for with_method: option in event route")
      [klass, action]
    end

    # Parses the target as a String, expecting it to be in the format "product#new_product"
    def self.validate_string_target(target)
      strings = target.split('#')
      raise('The string must be in a format like product#new_product') unless strings.count == 2
      klass = constantize_controller strings[0]
      action = strings[1].to_sym
      [klass, action]
    end

    def self.constantize_controller(controller_string)
      strings = (controller_string << '_controller').split('/')
      strings.map{|string| string.camelize}.join('::').constantize
    end

  end

end
