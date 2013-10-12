module WebsocketRails
  class Channel

    include Logging

    delegate :config, :channel_tokens, :channel_manager, :to => WebsocketRails

    attr_reader :name, :subscribers, :token, :events_sent

    def initialize(channel_name)
      @subscribers = []
      @name        = channel_name
      @private     = false
      @token       = generate_unique_token
      @events_sent = 0
    end

    def subscribe(connection)
      info "#{connection} subscribed to channel #{name}"
      trigger 'subscriber_join', connection.user if config.broadcast_subscriber_events?
      @subscribers << connection
      send_token connection
    end

    def unsubscribe(connection)
      return unless @subscribers.include? connection
      info "#{connection} unsubscribed from channel #{name}"
      @subscribers.delete connection
      trigger 'subscriber_part', connection.user if config.broadcast_subscriber_events?
    end

    def trigger(event_name,data={},options={})
      options.merge! :channel => name, :token => token
      options[:data] = data

      event = Event.new event_name, options

      info "[#{name}] #{event.data.inspect}"
      send_data event
    end

    def trigger_event(event)
      return if event.token != @token
      info "[#{name}] #{event.data.inspect}"
      send_data event
    end

    def make_private
      unless config.keep_subscribers_when_private?
        @subscribers.clear
      end
      @private = true
    end

    def is_private?
      @private
    end

    private

    def generate_unique_token
      begin
        token = SecureRandom.urlsafe_base64
      end while channel_tokens.include?(token)

      token
    end

    def send_token(connection)
      options = {
        :channel => @name,
        :data => {:token => @token},
        :connection => connection
      }
      info 'sending token'
      Event.new('websocket_rails.channel_token', options).trigger
    end

    def send_data(event)
      if WebsocketRails.synchronize? && event.server_token.nil?
        Synchronization.publish event
      end

      subscribers.each do |subscriber|
        subscriber.trigger event
      end

      @events_sent += 1
    end

  end
end
