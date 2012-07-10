module WebsocketRails
  class Channel

    attr_reader :name, :subscribers

    def initialize(channel_name)
      @subscribers = []
      @name = channel_name
    end

    def subscribe(connection)
      @subscribers << connection
    end

    def trigger(event_name,data={})
      data.merge! :channel => name
      event = Event.new event_name, data
      send_data event
    end

    def trigger_event(event)
      send_data event
    end

    private

    def send_data(event)
      subscribers.each do |subscriber|
        subscriber.trigger event
      end
    end

  end
end
