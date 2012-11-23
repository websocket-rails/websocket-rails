require "redis"
require "redis/connection/synchrony"

module WebsocketRails
  class Synchronization

    include Logging

    def self.redis
      @redis ||= Redis.new(WebsocketRails.redis_options)
    end

    def self.publish(event)
      Fiber.new do
        event.server_token = server_token
        redis.publish "websocket_rails.events", event.serialize
      end.resume
    end

    def self.server_token
      @server_token
    end

    def self.synchronize!
      unless @synchronizing
        @server_token = generate_unique_token
        register_server(@server_token)

        synchro = Fiber.new do
          EM::Synchrony.sleep(0.1)

          fiber_redis = Redis.connect(WebsocketRails.redis_options)
          fiber_redis.subscribe "websocket_rails.events" do |on|

            on.message do |channel, encoded_event|
              event = Event.new_from_json(encoded_event, nil)
              next if event.server_token == server_token

              WebsocketRails[event.channel].trigger_event(event)
            end
          end

          log "Beginning Synchronization"
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

    def self.shutdown!
      remove_server(server_token)
    end

    def self.generate_unique_token
      begin
        token = SecureRandom.urlsafe_base64
      end while redis.sismember("websocket_rails.active_servers", token)

      token
    end

    def self.register_server(token)
      Fiber.new do
        redis.sadd "websocket_rails.active_servers", token
        log "Server Registered: #{token}"
      end.resume
    end

    def self.remove_server(token)
      Fiber.new do
        redis.srem "websocket_rails.active_servers", token
        log "Server Removed: #{token}"
        EM.stop
      end.resume
    end

  end
end
