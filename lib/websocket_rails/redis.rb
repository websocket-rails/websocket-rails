module WebsocketRails
  module Redis
    def self.publish channel, event, data={}, options={}
      redis_obect = {
        :channel => channel,
        :event => event,
        :data => data,
        :options => options
      }
      jsn = redis_obect.to_json
    end
    
    
    def self.server
      ::Redis.new(:host => '127.0.0.1', :post => 6379)
    end
    
    class << self
       def [](channel)
          ChannelManager.new channel
      end
    end
    class ChannelManager
      attr_reader :name
      def initialize channel
        @name = channel
      end
      def trigger(event_name,data={},options={})
        
        redis_obect = {
          :channel => name,
          :event => event_name,
          :data => data,
          :options => options
        }
        WebsocketRails::Redis.server.publish 'ws', redis_obect.to_json
      end
    end
    
    
    class RedisSubscriber
      def initialize app
        @app = app
      end
      
      def call env
        start_thread  if WebsocketRails.stage?
        @app.call(env)
      end
      
      def start_thread
         Thread.new do
            WebsocketRails::Redis.server.subscribe('ws') do |on|
          
              on.message do |chan, msg|
               object = JSON.parse(msg, :symbolize_names => true )
               puts "sending message: #{object[:data]}"

               WebsocketRails[object[:channel].to_sym].trigger object[:event], object[:data], object[:options]
              end
            end
          end 
      end
    end
    
  end
end