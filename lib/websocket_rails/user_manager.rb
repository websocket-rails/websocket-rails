module WebsocketRails

  # Contains a Hash of all connected users. This
  # can be used to trigger an event on a specific
  # user from outside of a WebsocketRails controller.
  #
  # The key for a particular user is defined in the
  # configuration as `config.user_identifier`.
  #
  # If there is a `current_user` method defined
  # in ApplicationController and a user is signed
  # in to your application when the connection is
  # opened, WebsocketRails will call the method
  # defined in `config.user_identifier` on the
  # `current_user` object and use that value as
  # the key.
  #
  #   # In your events.rb file
  #   WebsocketRails.setup do |config|
  #     # Defaults to :id
  #     config.user_identifier = :name
  #   end
  #
  #   # In a standard controller or background job
  #   name = current_user.name
  #   WebsocketRails.users[name].send_message :event_name, data
  #
  # If no `current_user` method is defined or the
  # user is not signed in when the WebsocketRails
  # connection is opened, the connection will not be
  # stored in the UserManager.
  def self.users
    @user_manager ||= UserManager.new
  end

  class UserManager

    attr_reader :users

    def initialize
      @users = {}
    end

    def [](identifier)
      unless user = (@users[identifier.to_s] || find_remote_user(identifier.to_s))
        user = MissingConnection.new(identifier.to_s)
      end
      user
    end

    def []=(identifier, connection)
      @users[identifier.to_s] ||= LocalConnection.new
      @users[identifier.to_s] << connection
      Synchronization.register_user(connection) if WebsocketRails.synchronize?
    end

    def delete(connection)
      identifier = connection.user_identifier.to_s

      if (@users.has_key?(identifier) && @users[identifier].connections.count > 1)
        @users[identifier].delete(connection)
      else
        @users.delete(identifier)
        Synchronization.destroy_user(identifier) if WebsocketRails.synchronize?
      end
    end

    # Behaves similarly to Ruby's Array#each, yielding each connection
    # object stored in the {UserManager}. If synchronization is enabled,
    # each connection from every active worker will be yielded.
    #
    # You can access the `current_user` object through the #user method.
    #
    # You can trigger an event on this user using the #send_message method
    # which behaves identically to BaseController#send_message.
    #
    # If Synchronization is enabled, the state of the `current_user` object
    # will be equivalent to it's state at the time the connection was opened.
    # It will not reflect changes made after the connection has been opened.
    def each(&block)
      if WebsocketRails.synchronize?
        users_hash = Synchronization.all_users || return
        users_hash.each do |identifier, user_json|
          connection = remote_connection_from_json(identifier, user_json)
          block.call(connection) if block
        end
      else
        users.each do |_, connection|
          block.call(connection) if block
        end
      end
    end

    # Behaves similarly to Ruby's Array#map, invoking the given block with
    # each active connection object and returning a new array with the results.
    #
    # See UserManager#each for details on the current usage and limitations.
    def map(&block)
      collection = []

      each do |connection|
        collection << block.call(connection) if block
      end

      collection
    end

    private

    def find_remote_user(identifier)
      return unless WebsocketRails.synchronize?
      user_hash = Synchronization.find_user(identifier) || return

      remote_connection identifier, user_hash
    end

    def remote_connection_from_json(identifier, user_json)
      user_hash = JSON.parse(user_json)
      remote_connection identifier, user_hash
    end

    def remote_connection(identifier, user_hash)
      RemoteConnection.new identifier, user_hash
    end

    # The UserManager::LocalConnection Class serves as a proxy object
    # for storing multiple connections that belong to the same
    # user. It implements the same basic interface as a Connection.
    # This allows you to work with the object as though it is a
    # single connection, but still trigger the events on all
    # active connections belonging to the user.
    class LocalConnection

      attr_reader :connections

      def initialize
        @connections = []
      end

      def <<(connection)
        @connections << connection
      end

      def delete(connection)
        @connections.delete(connection)
      end

      def connected?
        true
      end

      def user_identifier
        latest_connection.user_identifier
      end

      def user
        latest_connection.user
      end

      def trigger(event)
        connections.each do |connection|
          connection.trigger event
        end
      end

      def send_message(event_name, data = {}, options = {})
        options.merge! :user_id => user_identifier
        options[:data] = data

        event = Event.new(event_name, options)

        # Trigger the event on all active connections for this user.
        connections.each do |connection|
          connection.trigger event
        end

        # Still publish the event in case the user is connected to
        # other workers as well.
        Synchronization.publish event if WebsocketRails.synchronize?
        true
      end

      private

      def latest_connection
        @connections.last
      end

    end

    class RemoteConnection

      attr_reader :user_identifier, :user

      def initialize(identifier, user_hash)
        @user_identifier = identifier.to_s
        @user_hash = user_hash
      end

      def connected?
        true
      end

      def user
        @user ||= load_user
      end

      def send_message(event_name, data = {}, options = {})
        options.merge! :user_id => @user_identifier
        options[:data] = data

        event = Event.new(event_name, options)

        # If the user is connected to this worker, trigger the event
        # immediately as the event will be ignored by the Synchronization
        ## dispatcher since the server_token will match.
        if connection = WebsocketRails.users.users[@user_identifier]
          connection.trigger event
        end

        # Still publish the event in case the user is connected to
        # other workers as well.
        #
        # No need to check for Synchronization being enabled here.
        # If a RemoteConnection has been fetched, Synchronization
        # must be enabled.
        Synchronization.publish event
        true
      end

      private

      def load_user
        user = WebsocketRails.config.user_class.new
        set_user_attributes user, @user_hash
        user
      end

      def set_user_attributes(user, attr)
        attr.each do |k, v|
          user.send "#{k}=", v
        end
        user.instance_variable_set(:@new_record, false)
        user.instance_variable_set(:@destroyed, false)
      end

    end

    class MissingConnection

      attr_reader :identifier

      def initialize(identifier)
        @user_identifier = identifier.to_s
      end

      def connected?
        false
      end

      def user
        nil
      end

      def send_message(*args)
        false
      end

      def nil?
        true
      end

    end

  end
end
