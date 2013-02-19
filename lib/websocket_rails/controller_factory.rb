module WebsocketRails
  class ControllerFactory

    attr_reader :controller_stores, :dispatcher

    def initialize(dispatcher)
      @dispatcher = dispatcher
      @controller_stores = {}
    end

    # TODO: Add deprecation notice for user defined
    # instance variables.
    # TODO: Add deprecation notice for defining
    # the `#initialize_session method`.
    def new_for_event(event, controller_class)
      controller = controller_class.new

      prepare(controller, event)

      controller
    end

    private

    def store_for_controller(controller)
      @controller_stores[controller.class] ||= DataStore::Controller.new(controller)
    end

    def prepare(controller, event)
      set_event(controller, event)
      set_dispatcher(controller, dispatcher)
      set_controller_store(controller)
      deprecation_check(controller)
    end

    def set_event(controller, event)
      set_ivar :@_event, controller, event
    end

    def set_dispatcher(controller, dispatcher)
      set_ivar :@_dispatcher, controller, dispatcher
    end

    def set_controller_store(controller)
      set_ivar :@_controller_store, controller, store_for_controller(controller)
    end

    def set_ivar(ivar, object, value)
      object.instance_variable_set(ivar, value)
    end

    def deprecation_check(controller)
      if controller.respond_to?(:initialize_session)
        raise InitializeSessionDeprecated.new
      end
    end

  end
end
