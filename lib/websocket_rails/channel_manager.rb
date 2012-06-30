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
      @channels = Hash.new.with_indifferent_access
    end

    def [](channel)
      @channels[channel] ||= Channel.new channel
    end

  end
end
