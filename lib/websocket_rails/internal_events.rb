module WebsocketRails
  class InternalEvents
    def self.events
      Proc.new do
        namespace :websocket_rails do
          subscribe :reload!, :to => InternalController, :with_method => :reload_controllers!
          subscribe :subscribe, :to => InternalController, :with_method => :subscribe_to_channel
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
        trigger_failure( { :reason => "channel is private", :hint => "use subscibe_private instead." } )
      end
    end

    def reload_controllers!
      return unless defined?(Rails) and Rails.env.development? || Rails.env.test?
      log 'reloading controllers'
      @_dispatcher.reload_controllers!
    end
  end
end
