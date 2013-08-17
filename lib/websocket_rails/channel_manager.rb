module WebsocketRails

  class << self

    def channel_manager
      @channel_manager ||= ChannelManager.new
    end

    def [](channel)
      channel_manager[channel]
    end

  end

  class ChannelManager

    attr_reader :channels

    def initialize
      @channels = {}.with_indifferent_access
    end

    def [](channel)
      @channels[channel] ||= Channel.new channel
    end

    def unsubscribe(connection)
      @channels.each do |channel_name, channel|
        channel.unsubscribe(connection)
      end
    end

  end
end
