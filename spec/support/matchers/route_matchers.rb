RSpec::Matchers.define :be_routed_to do |target|

  target_class, target_method = WebsocketRails::TargetValidator.validate_target target

  match do |event|
    raise ArgumentError, "event must be of type SpecHelperEvent" unless event.is_a? WebsocketRails::SpecHelperEvent
    result = false
    event.dispatcher.event_map.routes_for event do |controller, method|
      if controller.class == target_class and method == target_method
        result = true
        break
      end
    end
    result
  end

  failure_message_for_should do |event|
    "expected event #{event.name} to be routed to target #{target}"
  end

  failure_message_for_should_not do |event|
    "expected event #{event.name} not to be routed to target #{target}"
  end


  description do
    "expected event to be routed #{target}"
  end


end

RSpec::Matchers.define :be_routed_only_to do |target|
  target_class, target_method = WebsocketRails::TargetValidator.validate_target target

  match do |event|
    raise ArgumentError, "event must be of type SpecHelperEvent" unless event.is_a? WebsocketRails::SpecHelperEvent
    result = false
    no_of_routes = 0
    event.dispatcher.event_map.routes_for event do |controller, method|
      no_of_routes += 1
      if controller.class == target_class and method == target_method
        result = true
        break
      end
    end
    result and no_of_routes == 1
  end

  failure_message_for_should do |event|
    "expected event #{event.name} to be routed only to target #{target}"
  end

  failure_message_for_should_not do |event|
    "expected event #{event.name} not to be routed only to target #{target}"
  end


  description do
    "expected event to be routed #{target}"
  end
end
