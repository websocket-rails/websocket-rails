module WebsocketRails
  # The {DataStore} provides a convenient way to persist information between
  # execution of events. Since every event is executed within a new instance
  # of the controller class, instance variables set while processing an
  # action will be lost after the action finishes executing.
  #
  # There are two different {DataStore} classes that you can use:
  #
  # The {DataStore::Connection} class is unique for every active connection.
  # You can use it similar to the Rails session store. The connection data
  # store can be accessed within your controller using the `#connection_store`
  # method.
  #
  # The {DataStore::Controller} class is unique for every controller. You
  # can use it similar to how you would use instance variables within a
  # plain ruby class. The values set within the controller store will be
  # persisted between events. The controller store can be accessed within
  # your controller using the `#controller_store` method.
  module DataStore
    class Base < ActiveSupport::HashWithIndifferentAccess

      cattr_accessor :all_instances
      @@all_instances = Hash.new { |h,k| h[k] = [] }

      def self.clear_all_instances
        @@all_instances = Hash.new { |h,k| h[k] = [] }
      end

      def initialize
        instances << self
      end

      def instances
        all_instances[self.class]
      end

      def collect_all(key)
        collection = instances.each_with_object([]) do |instance, array|
          array << instance[key]
        end

        if block_given?
          collection.each do |item|
            yield(item)
          end
        else
          collection
        end
      end

      def destroy!
        instances.delete_if {|store| store.object_id == self.object_id }
      end

    end

    # The connection data store operates much like the {Controller} store. The
    # biggest difference is that the data placed inside is private for
    # individual users and accessible from any controller. Anything placed
    # inside the connection data store will be deleted when a user disconnects.
    #
    # The connection data store is accessed through the `#connection_store`
    # instance method inside your controller.
    #
    # If we were writing a basic chat system, we could use the connection data
    # store to hold onto a user's current screen name.
    #
    #
    #     class UserController < WebsocketRails::BaseController
    #
    #       def set_screen_name
    #         connection_store[:screen_name] = message[:screen_name]
    #       end
    #
    #     end
    #
    #     class ChatController < WebsocketRails::BaseController
    #
    #       def say_hello
    #         screen_name = connection_store[:screen_name]
    #         send_message :new_message, "#{screen_name} says hello"
    #       end
    #
    #     end
    class Connection < Base

      attr_accessor :connection

      def initialize(connection)
        super()
        @connection = connection
      end

    end

    # The Controller DataStore acts as a stand-in for instance variables in your
    # controller. At it's core, it is a Hash which is accessible inside your
    # controller through the `#controller_store` instance method. Any values
    # set in the controller store will be visible by all connected users which
    # trigger events that use that controller. However, values set in one
    # controller will not be visible by other controllers.
    #
    #
    #     class AccountController < WebsocketRails::BaseController
    #       # We will use a before filter to set the initial value
    #       before_action { controller_store[:event_count] ||= 0 }
    #
    #       # Mapped as `accounts.important_event` in the Event Router
    #       def important_event
    #         # This will be private for each controller
    #         controller_store[:event_count] += 1
    #         trigger_success controller_store[:event_count]
    #       end
    #     end
    #
    #     class ProductController < WebsocketRails::BaseController
    #       # We will use a before filter to set the initial value
    #       before_action { controller_store[:event_count] ||= 0 }
    #
    #       # Mapped as `products.boring_event` in the Event Router
    #       def boring_event
    #         # This will be private for each controller
    #         controller_store[:event_count] += 1
    #         trigger_success controller_store[:event_count]
    #       end
    #     end
    #
    #     # trigger `accounts.important_event`
    #     => 1
    #     # trigger `accounts.important_event`
    #     => 2
    #     # trigger `products.boring_event`
    #     => 1
    class Controller < Base

      attr_accessor :controller

      def initialize(controller)
        super()
        @controller = controller
      end

    end
  end
end
