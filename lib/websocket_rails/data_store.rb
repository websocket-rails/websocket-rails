module WebsocketRails
  # Provides a convenient way to persist data between events on a per client basis. Since every
  # events from every client is executed on the same instance of the controller object, instance
  # variables defined in actions will be shared between clients. The {DataStore} provides a Hash
  # that is private for each connected client. It is accessed through a WebsocketRails controller
  # using the {BaseController.data_store} instance method.
  #
  # = Example Usage
  # == Creating a user
  #   # action on ChatController called by :client_connected event
  #   def new_user
  #     # This would be overwritten when the next user joins
  #     @user = User.new( message[:user_name] )
  #
  #     # This will remain private for each user
  #     data_store[:user] = User.new( message[:user_name] )
  #   end
  #
  # == Collecting all Users from the DataStore
  # Calling the {#each} method will yield the Hash for all connected clients:
  #   # From your controller
  #   all_users = []
  #   data_store.each { |store| all_users << store[:user] }
  # The {DataStore} also uses method_missing to provide a convenience for the above case. Calling
  # +data_store.each_<key>+ from a controller where +<key>+ is the hash key that you wish to collect
  # will return an Array of the values for each connected client.
  #   # From your controller, assuming two users have already connected
  #   data_store[:user] = UserThree
  #   data_store.each_user
  #   => [UserOne,UserTwo,UserThree]
  module DataStore
    class Base < ActiveSupport::HashWithIndifferentAccess
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
