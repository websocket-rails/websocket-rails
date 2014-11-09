module WebsocketRails
  class Dispatcher

    include Logging

    attr_reader :event_map

    attr_reader :connection_manager

    attr_reader :controller_factory

    attr_reader :message_queue

    attr_reader :processor_registry

    delegate :filtered_channels, to: WebsocketRails

    def initialize(connection_manager)
      @connection_manager = connection_manager
      @controller_factory = ControllerFactory.new(self)
      @event_map          = EventMap.new
      @worker_threads     = WebsocketRails.config.worker_threads
      @message_queue      = EventQueue.new(@worker_threads)
      @processor_registry = MessageProcessors::Registry.new(self).init_processors!
    end

    def dispatch(message)
      @message_queue << message
    end

    def process_inbound
      @message_queue.pop do |message|
        processor_registry.processors_for(message).each do |processor|
          processor.message_queue << message
        end
      end
    end

    def broadcast_message(event)
      connection_manager.connections.map do |_, connection|
        connection.trigger event
      end
    end

    def reload_event_map!
      return unless defined?(Rails) and !Rails.configuration.cache_classes
      begin
        load "#{Rails.root}/config/events.rb"
        @event_map = EventMap.new
      rescue Exception => ex
        log(:warn, "EventMap reload failed: #{ex.message}")
      end
    end

  end
end
