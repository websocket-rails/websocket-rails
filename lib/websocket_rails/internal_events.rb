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
      channel_name = event.data[:channel]
      unless WebsocketRails[channel_name].is_private?
        WebsocketRails[channel_name].subscribe connection
        trigger_success
      else
        trigger_failure( { :reason => "channel is private", :hint => "use subscibe_private instead." } )
      end
    end
  end
end
