module WebsocketRails

  # This class is present also in another branch, if the branches are merged together, this class can go away
  class TargetValidator

    # Parses the target and extracts controller/action pair or raises an error if target is invalid
    def self.validate_target(target)
      case target
        when Hash
          validate_hash_target target
        when String
          validate_string_target target
      else
        raise('Must specify the event target either as a string product#new_product or as a Hash to: ProductController, with_method: :new_product')
      end
    end

  private

    # Parses the target as a Hash, expecting keys to: and with_method:
    def self.validate_hash_target(target)
      klass  = target[:to] || raise('Must specify a class for to: option in event route')
      action = target[:with_method] || raise('Must specify a method for with_method: option in event route')
      [klass, action]
    end

    # Parses the target as a String, expecting it to be in the format "product#new_product"
    def self.validate_string_target(target)
      strings = target.split('#')
      raise('The string must be in a format like product#new_product') unless strings.count == 2
      klass = "#{strings[0]}_controller".camelize.constantize
      action = strings[1].to_sym
      [klass, action]
    end

  end

end

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
    raise ArgumentError, 'event must be of type SpecHelperEvent' unless event.is_a? WebsocketRails::SpecHelperEvent
    result = false
    no_of_routes = 0
    event.dispatcher.event_map.routes_for event do |controller, method|
      no_of_routes += 1
      if controller.class == target_class and method == target_method
        result = true
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
