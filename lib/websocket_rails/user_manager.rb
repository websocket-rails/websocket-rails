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
  # connection is opened, the key will default to
  # `connection.id`.
  def self.users
    @user_manager ||= UserManager.new
  end

  class UserManager

    attr_reader :users

    def initialize
      @users = {}
    end

    def [](identifier)
      unless user = @users[identifier]
        user = MissingUser.new(identifier)
      end
      user
    end

    def []=(identifier, connection)
      @users[identifier] = connection
    end

    def delete(identifier)
      @users.delete(identifier)
    end

    class MissingUser

      def initialize(identifier)
        @identifier = identifier
      end

      def send_message(event_name, data = {}, options = {})
        if WebsocketRails.synchronize?
          options.merge! :user_id => @identifier
          options[:data] = data

          event = Event.new(event_name, options)
          Synchronization.publish event
          true
        else
          false
        end
      end

      def nil?
        true
      end

    end

  end
end
