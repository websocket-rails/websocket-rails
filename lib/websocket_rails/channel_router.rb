module WebsocketRails
  class ChannelRouter
    include Singleton

    DELIMITER = ':'

    class << self
      self.delegate :route!, to: :instance
    end

    def route!(event)
      controller = controller_for(event)
      return unless controller

      if controller.respond_to? event.name.to_sym
        controller.send(event.name.to_sym)
      end

      routes = controller.routes
      # Dispatch the event to every routes contigured
      routes.each do |route|
        WebsocketRails[route].trigger_event controller.event
      end
    end

    def controller_for(event)
      return nil unless klass = controller_class_for(event)

      klass.new(event)
    end

    def controller_name_for(event)
      return nil unless event.is_channel?

      event.channel.to_s.split(DELIMITER).first.to_sym
    end

    def controller_class_for(event)
      return nil unless chan = controller_name_for(event)

      begin
        "Channels::#{chan.to_s.camelize}Controller".constantize
      rescue NameError
        ChannelController
      end
    end

  end
end
