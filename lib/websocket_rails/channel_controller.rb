module WebsocketRails
  class ChannelController
    attr_reader :event

    def initialize(event)
      @_controller = Hash.new
      @event = event

      default_action
    end

    def default_action
      route :default
    end

    def context
      list = event.channel.to_s.split(ChannelRouter::DELIMITER).drop 1
      list.empty? ? nil : list
    end

    def route(opts = nil)
      # Clear routes and return if called with :none
      return @_controller[:routes] = nil if opts == :none

      # Set route back to original event's channel.
      opts = {to: event.channel} if opts == :default

      if opts.has_key? :to
        @_controller[:routes] = [opts[:to]]
      end

      # Add the given route to the list of route the event will be sent to
      if opts.has_key? :add
        if @_controller[:routes].is_a? Array
          @_controller[:routes] << opts[:add]
          @_controller[:routes].flatten!
        else # We're adding to nil route
          @_controller[:routes] = [opts[:add]]
        end
      end
    end

    # Return the list of route or an empty list i
    def routes
      if @_controller[:routes].is_a? Array
        @_controller[:routes]
      elsif @_controller[:routes]
        [@_controller[:routes]]
      else
        []
      end
    end
  end
end
