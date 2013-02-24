module WebsocketRails
  class Channel

    include Logging

    attr_reader :name, :subscribers

    def initialize(channel_name)
      @subscribers = []
      @name        = channel_name
      @private     = false
    end

    def subscribe(connection)
      info "#{connection} subscribed to channel #{name}"
      @subscribers << connection
    end

    def trigger(event_name,data={},options={})
      options.merge! :channel => name
      options[:data] = data

      event = Event.new event_name, options

      send_data event
    end

    def trigger_event(event)
      info "(processing_channel_event) name: #{event.name} namespace: #{event.namespace} connection: #{event.connection.id}"
      send_data event
    end

    def make_private
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

  end
end
