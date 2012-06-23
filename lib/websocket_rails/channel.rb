module WebsocketRails
  class Channel

    attr_reader :name, :connections

    def initialize(channel_name)
      @connections = []
      @name = channel_name
    end

    def join(connection)
      @connections << connection
    end

    def trigger(event_name,data,options={})
      options.merge! :channel => name
      event = Event.new event_name, data, options
      send_data event
    end

    def send_data(event)
      connections.each do |connection|
        connection.send event.serialize
      end
    end

  end
end
