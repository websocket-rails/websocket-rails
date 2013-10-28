module Channels
  class MyChanController < WebsocketRails::ChannelController
    def initialize(event)
      super
    end

    def action
      route :default
      # also Duplicate to some other chan
      route add: :other_chan
    end

    def default_action
      route :none
    end
  end

  class OtherChanController < WebsocketRails::ChannelController
  end
end
