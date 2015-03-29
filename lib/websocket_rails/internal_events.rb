module WebsocketRails
  class InternalEvents
    def self.events
      Proc.new do
        subscribes = Proc.new do
          subscribe :pong, :to => InternalController, :with_method => :do_pong
          subscribe :subscribe, :to => InternalController, :with_method => :subscribe_to_channel
          subscribe :unsubscribe, :to => InternalController, :with_method => :unsubscribe_to_channel
        end

        if WebsocketRails.config.system_namespace == :global
          subscribes.call
        else
          namespace WebsocketRails.config.system_namespace do
            subscribes.call
          end
        end
      end
    end
  end

  class InternalController < BaseController
    include Logging

    def subscribe_to_channel
      channel_name = event.data[:channel]
      unless WebsocketRails[channel_name].is_private?
        WebsocketRails[channel_name].subscribe connection
        trigger_success
      else
        trigger_failure( { :reason => "channel is private", :hint => "use subscribe_private instead." } )
      end
    end

    def unsubscribe_to_channel
      channel_name = event.data[:channel]
      WebsocketRails[channel_name].unsubscribe connection
      trigger_success
    end

    def do_pong
      connection.pong = true
    end
  end
end
