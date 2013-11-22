module WebsocketRails
  class ControllerFactory

    attr_reader :controller_stores, :dispatcher

    def initialize(dispatcher)
      @dispatcher = dispatcher
      @controller_stores = {}
      @initialized_controllers = {}
    end

    # TODO: Add deprecation notice for user defined
    # instance variables.
    def new_for_event(event, controller_class, method)
      controller_class = reload!(controller_class)
      controller = controller_class.new

      prepare(controller, event, method)

      controller
    end

    private

    def store_for_controller(controller)
      @controller_stores[controller.class] ||= DataStore::Controller.new(controller)
    end

    def prepare(controller, event, method)
      set_event(controller, event)
      set_dispatcher(controller, dispatcher)
      set_controller_store(controller)
      set_action_name(controller, method)
      initialize_controller(controller)
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

    def set_action_name(controller, method)
      set_ivar :@_action_name, controller, method.to_s
    end

    def set_ivar(ivar, object, value)
      object.instance_variable_set(ivar, value)
    end

    def initialize_controller(controller)
      unless @initialized_controllers[controller.class] == true
        controller.send(:initialize_session) if controller.respond_to?(:initialize_session)
        @initialized_controllers[controller.class] = true
      end
    end

    # Reloads the controller class to pick up code changes
    # while in the development environment.
    def reload!(controller)
      return controller unless defined?(Rails) and !Rails.configuration.cache_classes
      # we don't reload our own controller as we assume it provide as 'library'
      unless controller.name == "WebsocketRails::InternalController"
        class_name = controller.name
        filename = class_name.underscore
        load "#{filename}.rb"
        return class_name.constantize
      end

      return controller
    end

  end
end
