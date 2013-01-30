def compare_data(event, data)
  return true if data.nil?
  return true if data == :any and event.data
  return true if data == :nil and event.data.nil?
  data.eql? event.data
end

def data_for_spec_message(data)
  case data
    when nil
      ''
    when :nil
      'with no data'
    when :any
      'with any data'
    else
      "with data #{data}"
  end
end

RSpec::Matchers.define :trigger_message do |data|

  match do |event|
    event.triggered and compare_data(event, data)
  end

  failure_message_for_should do |event|
    "expected #{event.name} to trigger message #{data_for_spec_message data}"
  end

  failure_message_for_should_not do |event|
    "expected #{event.name} not to trigger message #{data_for_spec_message data}"
  end

  description do
    "expected event to trigger message #{data_for_spec_message data}"
  end

end

RSpec::Matchers.define :trigger_success_message do |data|

  match do |event|
    event.triggered and event.success == true and compare_data(event, data)
  end

  failure_message_for_should do |event|
    "expected #{event.name} to trigger success message #{data_for_spec_message data}"
  end

  failure_message_for_should_not do |event|
    "expected #{event.name} not to trigger success message #{data_for_spec_message data}"
  end

  description do
    "expected event to trigger success message #{data_for_spec_message data}"
  end

end

RSpec::Matchers.define :trigger_failure_message do |data|

  match do |event|
    event.triggered and event.success == false and compare_data(event, data)
  end

  failure_message_for_should do |event|
    "expected #{event.name} to trigger failure message #{data_for_spec_message data}"
  end

  failure_message_for_should_not do |event|
    "expected #{event.name} not to trigger failure message #{data_for_spec_message data}"
  end

  description do
    "expected event to trigger failure message #{data_for_spec_message data}"
  end

end
