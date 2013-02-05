module WebsocketRails

  module SpecHelpers

    def self.compare_trigger_data(event, data)
      return true if data.nil?
      return true if data == :any and event.data
      return true if data == :nil and event.data.nil?
      data.eql? event.data
    end

    def self.expected_data_for_spec_message(data)
      case data
        when nil
          ''
        when :nil
          ' with no data'
        when :any
          ' with some data'
        else
          " with data #{data}"
      end
    end

    def self.actual_data_for_spec_message(data)
      data ? "with data #{data}": 'with no data'
    end

    def self.actual_for_spec_message(event, success)
      if event.triggered?
        if success.nil?
          "triggered message #{actual_data_for_spec_message(event.data)}"
        else
          "triggered #{event.success ? 'a success' : 'a failure' } message #{actual_data_for_spec_message(event.data)}"
        end
      else
        'did not trigger any message'
      end
    end

    def self.verify_trigger(event, data, success)
      return false unless event.triggered?
      return false unless compare_trigger_data(event, data)
      success.nil? || success == event.success
    end

  end

end


RSpec::Matchers.define :trigger_message do |data|

  match do |event|
    WebsocketRails::SpecHelpers.verify_trigger event, data, nil
  end

  failure_message_for_should do |event|
    "expected #{event.encoded_name} to trigger message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}, " +
        "instead it #{WebsocketRails::SpecHelpers.actual_for_spec_message event, nil}"
  end

  failure_message_for_should_not do |event|
    "expected #{event.encoded_name} not to trigger message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

  description do
    "trigger message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

end

RSpec::Matchers.define :trigger_success_message do |data|

  match do |event|
    WebsocketRails::SpecHelpers.verify_trigger event, data, true
  end

  failure_message_for_should do |event|
    "expected #{event.encoded_name} to trigger success message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}, "+
        "instead it #{WebsocketRails::SpecHelpers.actual_for_spec_message event, true}"
  end

  failure_message_for_should_not do |event|
    "expected #{event.encoded_name} not to trigger success message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

  description do
    "trigger success message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

end

RSpec::Matchers.define :trigger_failure_message do |data|

  match do |event|
    WebsocketRails::SpecHelpers.verify_trigger event, data, false
  end

  failure_message_for_should do |event|
    "expected #{event.encoded_name} to trigger failure message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}, " +
        "instead it #{WebsocketRails::SpecHelpers.actual_for_spec_message event, true}"
  end

  failure_message_for_should_not do |event|
    "expected #{event.encoded_name} not to trigger failure message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

  description do
    "trigger failure message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

end
