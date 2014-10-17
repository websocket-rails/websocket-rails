require "redis"
require "redis/connection/ruby"
require "connection_pool"

module WebsocketRails

  module Synchronization

    def self.sync
      @sync ||= Synchronize.new
    end

    class Synchronize

      delegate :connection_manager, to: WebsocketRails
      delegate :dispatcher, to: :connection_manager

      include Logging

      def initialize
        @dispatch_queue = EventQueue.new
        @publish_queue = EventQueue.new
      end

      def redis_pool(redis_options)
        ConnectionPool::Wrapper.new(size: WebsocketRails.config.synchronize_pool_size) do
          Redis.new(redis_options)
        end
      end

      def redis
        @redis ||= begin
          redis_options = WebsocketRails.config.redis_options
          EM.reactor_running? ? redis_pool(redis_options) : ruby_redis
        end
      end

      def ruby_redis
        @ruby_redis ||= begin
          redis_options = WebsocketRails.config.redis_options.merge(:driver => :ruby)
          redis_pool(redis_options)
        end
      end

      def publish_remote(message)
        message.server_token = server_token
        redis.publish "websocket_rails.events", message.serialize
      end

      def server_token
        @server_token
      end

      def synchronize!
        unless @synchronizing
          @publish_queue.pop do |message|
            publish_remote(message)
          end
          @dispatch_queue.pop do |message|
            process_inbound message
          end
          @server_token = generate_server_token
          register_server(@server_token)

          @synchro = Thread.new do
            fiber_redis = Redis.connect(WebsocketRails.config.redis_options)
            fiber_redis.subscribe "websocket_rails.events" do |on|

              on.message do |_, encoded_message|
                message = Event.deserialize(encoded_message, nil)

                # Do nothing if this is the server that sent this event.
                next if message.server_token == server_token

                # Ensure an event never gets triggered twice. Events added to the
                # redis queue from other processes may not have a server token
                # attached.
                message.server_token = server_token if message.server_token.nil?

                @dispatch_queue << message
              end
            end

            info "Beginning Synchronization"
          end

          @synchronizing = true

          trap('TERM') do
            Thread.new { shutdown!; exit }
          end
          trap('INT') do
            Thread.new { shutdown!; exit }
          end
          trap('QUIT') do
            Thread.new { shutdown!; exit }
          end
        end
      end

      def process_inbound(message)
        dispatcher.dispatch message
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
      end

      def register_remote_user(connection)
        Fiber.new do
          id = connection.user_identifier
          user = connection.user
          redis.hset 'websocket_rails.users', id, user.as_json(root: false).to_json
        end.resume
      end

      def destroy_remote_user(identifier)
        Fiber.new do
          redis.hdel 'websocket_rails.users', identifier
        end.resume
      end

      def find_remote_user(identifier)
        Fiber.new do
          raw_user = redis.hget('websocket_rails.users', identifier)
          raw_user ? JSON.parse(raw_user) : nil
        end.resume
      end

      def all_remote_users
        Fiber.new do
          redis.hgetall('websocket_rails.users')
        end.resume
      end

    end
  end
end
