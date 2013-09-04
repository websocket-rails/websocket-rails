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
      unless user = (@users[identifier] || find_remote_user(identifier))
        user = MissingConnection.new(identifier)
      end
      user
    end

    def []=(identifier, connection)
      @users[identifier.to_s] = connection
      Synchronization.register_user(connection) if WebsocketRails.synchronize?
    end

    def delete(identifier)
      connection = @users.delete(identifier.to_s)
      Synchronization.destroy_user(connection) if WebsocketRails.synchronize?
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
          user_hash = JSON.parse(user_json)
          connection = load_user_from_hash(identifier, user_hash)
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

      load_user_from_hash identifier, user_hash
    end

    def load_user_from_hash(identifier, user_hash)
      user = WebsocketRails.config.user_class.new

      set_user_attributes user, user_hash

      RemoteConnection.new(identifier, user)
    end

    def set_user_attributes(user, attr)
      attr.each do |k, v|
        user.send "#{k}=", v
      end
      user.instance_variable_set(:@new_record, false)
      user.instance_variable_set(:@destroyed, false)
    end

    class RemoteConnection

      attr_reader :user_identifier, :user

      def initialize(identifier, user)
        @user_identifier = identifier.to_s
        @user = user
      end

      def connected?
        true
      end

      def send_message(event_name, data = {}, options = {})
        options.merge! :user_id => @user_identifier
        options[:data] = data

        # No need to check for Synchronization being enabled here.
        # If a RemoteConnection has been fetched, Synchronization
        # must be enabled.
        event = Event.new(event_name, options)

        # If the user is connected to this worker, trigger the event
        # immediately as the event will be ignored by the Synchronization
        # dispatcher since the server_token will match.
        if connection = WebsocketRails.users.users[@user_identifier]
          connection.trigger event
        end

        # Still publish the event in case the user is connected to
        # other workers as well.
        Synchronization.publish event
        true
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
