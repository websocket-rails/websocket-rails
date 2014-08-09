module WebsocketRails
  class Channel

    include Logging

    delegate :config, :channel_manager, :filtered_channels, :to => WebsocketRails
    delegate :redis, :to => Synchronization

    attr_reader :name, :subscribers

    def initialize(channel_name)
      @subscribers = []
      @name        = channel_name
      @private     = false
    end

    def subscribe(connection)
      info "#{connection} subscribed to channel #{@name}"
      trigger 'subscriber_join', connection.user if config.broadcast_subscriber_events?
      @subscribers << connection
      send_token connection
    end

    def unsubscribe(connection)
      return unless @subscribers.include? connection
      info "#{connection} unsubscribed from channel #{@name}"
      @subscribers.delete connection
      trigger 'subscriber_part', connection.user if config.broadcast_subscriber_events?
    end

    def trigger(event_name,data={},options={})
      options.merge! :channel => @name, :token => token
      options[:data] = data

      event = Event.new event_name, options

      info "[#{@name}] #{event.data.inspect}"
      send_data event
    end

    def trigger_event(event)
      return if event.token != token
      info "T:[#{@name}] #{event.data.inspect}"
      info "total: #{@subscribers.count}, unique: #{@subscribers.uniq.count}"
      send_data event
    end

    def make_private
      unless config.keep_subscribers_when_private?
        @subscribers.clear
      end
      @private = true
    end

    def filter_with(controller, catch_all=nil)
      filtered_channels[@name] = catch_all.nil? ? controller : [controller, catch_all]
    end

    def is_private?
      @private
    end

    def token
      @token ||= channel_token
    end

    def broadcast_subscribers(event)
      return if event.token != token
      info "B:[#{@name}] #{event.data.inspect}"
      info "total: #{@subscribers.count}, unique: #{@subscribers.uniq.count}"
      broadcast event
    end

    private

    def channel_token
      channel_token = redis.with {|conn| conn.hget('websocket_rails.channel_tokens', name)}
      if channel_token.nil?
        generate_unique_token
      else
        channel_token
      end
    end

    def generate_unique_token
      begin
        new_token = SecureRandom.uuid
      end while redis.with {|conn| conn.hvals('websocket_rails.channel_tokens')}.include?(new_token)

      new_token
    end

    def send_token(connection)
      options = {
        :channel => @name,
        :data => {:token => token},
        :connection => connection
      }
      info 'sending token'
      Event.new('websocket_rails.channel_token', options).trigger
    end

    def send_data(event)
      if WebsocketRails.synchronize? && event.server_token.nil?
        Synchronization.publish event
      end
      broadcast(event)

    end

    def broadcast(event)
      return unless @subscribers.count > 0

      @subscribers.uniq.each do |subscriber|
        subscriber.trigger event
      end
    end

  end
end
