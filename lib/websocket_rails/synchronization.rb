require "redis/connection/synchrony"
require "redis"
require "redis/connection/ruby"

module WebsocketRails
  class Synchronization

    def self.publish(event)
      singleton.publish event
    end

    def self.synchronize!
      singleton.synchronize!
    end

    def self.shutdown!
      singleton.shutdown!
    end

    def self.singleton
      @singleton ||= new
    end

    include Logging

    def redis
      @redis ||= Redis.new(WebsocketRails.config.redis_options)
    end

    def ruby_redis
      @ruby_redis ||= begin
        redis_options = WebsocketRails.config.redis_options.merge(:driver => :ruby)
        Redis.new(redis_options)
      end
    end

    def publish(event)
      Fiber.new do
        redis_client = EM.reactor_running? ? redis : ruby_redis
        event.server_token = server_token
        redis_client.publish "websocket_rails.events", event.serialize
      end.resume
    end

    def server_token
      @server_token
    end

    def synchronize!
      unless @synchronizing
        @server_token = generate_unique_token
        register_server(@server_token)

        synchro = Fiber.new do
          fiber_redis = Redis.connect(WebsocketRails.config.redis_options)
          fiber_redis.subscribe "websocket_rails.events" do |on|

            on.message do |channel, encoded_event|
              event = Event.new_from_json(encoded_event, nil)
              next if event.server_token == server_token

              WebsocketRails[event.channel].trigger_event(event)
            end
          end

          info "Beginning Synchronization"
        end

        @synchronizing = true

        EM.next_tick { synchro.resume }

        trap('TERM') do
          shutdown!
        end
        trap('INT') do
          shutdown!
        end
        trap('QUIT') do
          shutdown!
        end
      end
    end

    def shutdown!
      remove_server(server_token)
    end

    def generate_unique_token
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
      Fiber.new do
        redis.srem "websocket_rails.active_servers", token
        info "Server Removed: #{token}"
        EM.stop
      end.resume
    end

  end
end
