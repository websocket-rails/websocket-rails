require "redis/connection/synchrony"
require "redis"
require "redis/connection/ruby"

module WebsocketRails
  class Synchronization

    def self.all_users
      singleton.all_users
    end

    def self.find_user(connection)
      singleton.find_user connection
    end

    def self.register_user(connection)
      singleton.register_user connection
    end

    def self.destroy_user(connection)
      singleton.destroy_user connection
    end

    def self.publish(event)
      singleton.publish event
    end

    def self.synchronize!
      singleton.synchronize!
    end

    def self.shutdown!
      singleton.shutdown!
    end

    def self.redis
      singleton.redis
    end

    def self.singleton
      @singleton ||= new
    end

    include Logging

    def redis
      @redis ||= begin
        redis_options = WebsocketRails.config.redis_options
        EM.reactor_running? ? Redis.new(redis_options) : ruby_redis
      end
    end

    def ruby_redis
      @ruby_redis ||= begin
        redis_options = WebsocketRails.config.redis_options.merge(:driver => :ruby)
        Redis.new(redis_options)
      end
    end

    def publish(event)
      Fiber.new do
        event.server_token = server_token
        redis.publish "websocket_rails.events", event.serialize
      end.resume
    end

    def server_token
      @server_token
    end

    def synchronize!
      unless @synchronizing
        @server_token = generate_server_token
        register_server(@server_token)

        synchro = Fiber.new do
          fiber_redis = Redis.connect(WebsocketRails.config.redis_options)
          fiber_redis.subscribe "websocket_rails.events" do |on|

            on.message do |_, encoded_event|
              event = Event.new_from_json(encoded_event, nil)

              # Do nothing if this is the server that sent this event.
              next if event.server_token == server_token

              # Ensure an event never gets triggered twice. Events added to the
              # redis queue from other processes may not have a server token
              # attached.
              event.server_token = server_token if event.server_token.nil?

              trigger_incoming event
            end
          end

          info "Beginning Synchronization"
        end

        @synchronizing = true

        EM.next_tick { synchro.resume }

        trap('TERM') do
          Thread.new { shutdown! }
        end
        trap('INT') do
          Thread.new { shutdown! }
        end
        trap('QUIT') do
          Thread.new { shutdown! }
        end
      end
    end

    def trigger_incoming(event)
      case
      when event.is_channel?
        WebsocketRails[event.channel].trigger_event(event)
      when event.is_user?
        connection = WebsocketRails.users[event.user_id.to_s]
        return if connection.nil?
        connection.trigger event
      end
    end

    def shutdown!
      remove_server(server_token)
    end

    def generate_server_token
      begin
        token = SecureRandom.urlsafe_base64
      end while redis.sismember("websocket_rails.active_servers", token)

      token
    end

    def register_server(token)
      Fiber.new do
        redis.sadd "websocket_rails.active_servers", token
        info "Server Registered: #{token}"
      end.resume
    end

    def remove_server(token)
      ruby_redis.srem "websocket_rails.active_servers", token
      info "Server Removed: #{token}"
      EM.stop
    end

    def register_user(connection)
      Fiber.new do
        id = connection.user_identifier
        user = connection.user
        redis.hset 'websocket_rails.users', id, user.as_json(root: false).to_json
      end.resume
    end

    def destroy_user(identifier)
      Fiber.new do
        redis.hdel 'websocket_rails.users', identifier
      end.resume
    end

    def find_user(identifier)
      Fiber.new do
        raw_user = redis.hget('websocket_rails.users', identifier)
        raw_user ? JSON.parse(raw_user) : nil
      end.resume
    end

    def all_users
      Fiber.new do
        redis.hgetall('websocket_rails.users')
      end.resume
    end

  end
end
