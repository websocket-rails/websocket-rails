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
        collection = []
        instances.each do |instance|
          collection << instance[key]
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

    class Connection < Base

      attr_accessor :connection

      def initialize(connection)
        super()
        @connection = connection
      end

    end

    class Controller < Base

      attr_accessor :controller

      def initialize(controller)
        super()
        @controller = controller
      end

    end
  end
end
