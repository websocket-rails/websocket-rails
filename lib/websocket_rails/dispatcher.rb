module WebsocketRails
  class Dispatcher

    include Logging

    attr_reader :event_map, :connection_manager, :controller_factory

    def initialize(connection_manager)
      @connection_manager = connection_manager
      @controller_factory = ControllerFactory.new(self)
      @event_map = EventMap.new(self)
    end

    def receive_encoded(encoded_data,connection)
      event = Event.new_from_json( encoded_data, connection )
      dispatch( event )
    end

    def receive(event_name,data,connection)
      event = Event.new event_name, data, connection
      dispatch( event )
    end

    def dispatch(event)
      return if event.is_invalid?

      if event.is_channel?
        WebsocketRails[event.channel].trigger_event event
      else
        reload_event_map! unless event.is_internal?
        route event
      end
    end

    def send_message(event)
      event.connection.trigger event
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
        @event_map = EventMap.new(self)
      rescue Exception => ex
        log(:warn, "EventMap reload failed: #{ex.message}")
      end
    end

    private

    def route(event)
      actions = []
      event_map.routes_for event do |controller_class, method|
        actions << Fiber.new do
          begin
            log_event(event) do
              controller = controller_factory.new_for_event(event, controller_class, method)

              controller.process_action(method, event)
            end
          rescue Exception => ex
            event.success = false
            event.data = extract_exception_data ex
            event.trigger
          end
        end
      end
      execute actions
    end

    def execute(actions)
      actions.map do |action|
        EM.next_tick { action.resume }
      end
    end

    def extract_exception_data(ex)
      if record_invalid_defined? and ex.is_a? ActiveRecord::RecordInvalid
        {
          :record => ex.record.attributes,
          :errors => ex.record.errors,
          :full_messages => ex.record.errors.full_messages
        }
      else
        ex if ex.respond_to?(:to_json)
      end
    end

    def record_invalid_defined?
      Object.const_defined?('ActiveRecord') and ActiveRecord.const_defined?('RecordInvalid')
    end


  end
end
