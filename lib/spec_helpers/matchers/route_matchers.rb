module WebsocketRails

  module SpecHelpers

      def self.verify_route(event, target, non_exclusive)

        raise ArgumentError, 'event must be of type SpecHelperEvent' unless event.is_a? WebsocketRails::SpecHelperEvent
        target_class, target_method = WebsocketRails::TargetValidator.validate_target target

        result = false
        no_of_routes = 0
        event.dispatcher.event_map.routes_for event do |controller_class, method|
          no_of_routes += 1
          controller = controller_class.new
          if controller.class == target_class and method == target_method
            result = true
          end
        end
        result and (non_exclusive or no_of_routes == 1)
      end

  end

end


RSpec::Matchers.define :be_routed_to do |target|

  match do |event|
    WebsocketRails::SpecHelpers.verify_route event, target, true
  end

  failure_message_for_should do |event|
    "expected event #{event.name} to be routed to target #{target}"
  end

  failure_message_for_should_not do |event|
    "expected event #{event.name} not to be routed to target #{target}"
  end

  description do
    "be routed to target #{target}"
  end

end

RSpec::Matchers.define :be_routed_only_to do |target|

  match do |event|
    WebsocketRails::SpecHelpers.verify_route event, target, false
  end

  failure_message_for_should do |event|
    "expected event #{event.name} to be routed only to target #{target}"
  end

  failure_message_for_should_not do |event|
    "expected event #{event.name} not to be routed only to target #{target}"
  end

  description do
    "be routed only to target #{target}"
  end

end
