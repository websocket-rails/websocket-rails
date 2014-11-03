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

    def self.actual_for_spec_message(event)
      if event.triggered?
        success = event.success
        if success.nil?
          "triggered message #{actual_data_for_spec_message(event.data)}"
        else
          success_state = 
          case success
          when 0 then "a success"
          when 1 then "a failure"
          when 2 then "a no result"
          else success
          end
          "triggered #{success_state} message #{actual_data_for_spec_message(event.data)}"
        end
      else
        'did not trigger any message'
      end
    end

    def self.verify_trigger(event, data, success=nil)
      return false unless event.triggered?
      return false unless compare_trigger_data(event, data)
      success.nil? || success == event.success
    end

  end

end


RSpec::Matchers.define :trigger_message do |data|
  match do |event|
    WebsocketRails::SpecHelpers.verify_trigger event, data
  end

  failure_message_for_should do |event|
    "expected #{event.encoded_name} to trigger message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}, " +
        "instead it #{WebsocketRails::SpecHelpers.actual_for_spec_message event}"
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
    WebsocketRails::SpecHelpers.verify_trigger event, data, 0
  end

  failure_message_for_should do |event|
    "expected #{event.encoded_name} to trigger success message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}, "+
        "instead it #{WebsocketRails::SpecHelpers.actual_for_spec_message event}"
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
    WebsocketRails::SpecHelpers.verify_trigger event, data, 1
  end

  failure_message_for_should do |event|
    "expected #{event.encoded_name} to trigger failure message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}, " +
        "instead it #{WebsocketRails::SpecHelpers.actual_for_spec_message event}"
  end

  failure_message_for_should_not do |event|
    "expected #{event.encoded_name} not to trigger failure message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

  description do
    "trigger failure message#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end

end

Rspec::Matchers.define :trigger_no_result_message do |data|
  match do |event|
    WebsocketRails::SpecHelpers.verify_trigger event, data, 2
  end

  failure_message_for_should do |event|
    "expected #{event.encoded_name} to trigger no result message (success == 2)#{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}, "+
      "instead it #{WebsocketRails::SpecHelpers.actual_for_spec_message event}"
  end

  failure_message_for_should_not do |event|
    "expected #{event.encoded_name} not to trigger no result message (success == 2)"
  end

  description do 
    "trigger no result message #{WebsocketRails::SpecHelpers.expected_data_for_spec_message data}"
  end
end