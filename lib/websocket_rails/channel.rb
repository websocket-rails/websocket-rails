module WebsocketRails
  class Channel

    include Logging

    delegate :config, :channel_tokens, :channel_manager, :to => WebsocketRails

    attr_reader :name, :subscribers, :token

    def initialize(channel_name)
      @subscribers = []
      @name        = channel_name
      @private     = false
      @token       = generate_unique_token
    end

    def subscribe(connection)
      info "#{connection} subscribed to channel #{name}"
      @subscribers << connection
    end

    def unsubscribe(connection)
      return unless @subscribers.include? connection
      info "#{connection} unsubscribed from channel #{name}"
      @subscribers.delete connection

      if @subscribers.empty?
        channel_manager.channels.delete(name)
      end
    end

    def trigger(event_name,data={},options={})
      options.merge! :channel => name
      options[:data] = data

      event = Event.new event_name, options

      info "[#{name}] #{event.data.inspect}"
      send_data event
    end

    def trigger_event(event)
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

    def send_data(event)
      if WebsocketRails.synchronize? && event.server_token.nil?
        Synchronization.publish event
      end

      subscribers.each do |subscriber|
        subscriber.trigger event
      end
    end

    def generate_unique_token
      begin
        token = SecureRandom.urlsafe_base64
      end while channel_tokens.include?(token)

      token
    end

  end
end
