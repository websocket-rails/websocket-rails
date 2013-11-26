module WebsocketRails
  class Channel

    include Logging

    delegate :config, :channel_tokens, :channel_manager, :filtered_channels, :to => WebsocketRails

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

    def trigger(event_name, data={}, options={})
      options.merge! :channel => @name, :token => token

      event = Event.new(event_name, data, options)

      info "[#{@name}] #{event.data.inspect}"
      send_data event
    end

    def trigger_event(event)
      return if event.token != token
      info "[#{@name}] #{event.data.inspect}"
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
      @token ||= channel_tokens[@name] ||= generate_unique_token
    end

    private

    def generate_unique_token
      begin
        new_token = SecureRandom.uuid
      end while channel_tokens.values.include?(new_token)

      new_token
    end

    def send_token(connection)
      options = {
        :channel => @name,
        :connection => connection
      }
      info 'sending token'
      Event.new('websocket_rails.channel_token', {token: token}, options).trigger
    end

    def send_data(event)
      return unless event.should_propagate?
      if WebsocketRails.synchronize? && event.server_token.nil?
        Synchronization.publish event
      end

      @subscribers.each do |subscriber|
        subscriber.trigger event
      end
    end

  end
end
