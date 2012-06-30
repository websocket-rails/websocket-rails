module WebsocketRails
  class InternalEvents
    def self.events
      Proc.new do
        namespace :websocket_rails do
          subscribe :subscribe, :to => InternalController, :with_method => :subscribe_to_channel
        end
      end
    end
  end

  class InternalController < BaseController
    def subscribe_to_channel
      puts "subscribed to: #{data[:channel]}"
      channel_name = data[:channel]
      WebsocketRails[channel_name].subscribe connection
    end
  end
end
