module WebsocketRails

  class << self

    def channel_manager
      return @channel_manager if @channel_manager

      @channel_manager = ChannelManager.new
    end

    def [](channel)
      channel_manager[channel]
    end

    def channel_tokens
      channel_manager.channel_tokens
    end

    def filtered_channels
      channel_manager.filtered_channels
    end

  end

  class ChannelManager

    attr_reader :channels, :filtered_channels
    delegate :sync, to: Synchronization


    def initialize
      @mutex= Mutex.new
      @channels = {}.with_indifferent_access
      @filtered_channels = {}.with_indifferent_access
    end

    def register_channel(name, token)
      sync.register_channel if WebsocketRails.synchronize?
      channel_tokens[name] = token
    end

    def channel_tokens
      return sync.channel_tokens if WebsocketRails.synchronize?
      return @channel_tokens if @channel_tokens
      @channel_tokens = {}
    end

    def [](channel)
     @mutex.synchronize do

       return @channels[channel] if @channels[channel]

       @channels[channel] = Channel.new(channel)
      end
    end

    def unsubscribe(connection)
      @channels.each do |channel_name, channel|
        channel.unsubscribe(connection)
      end
    end

  end
end
