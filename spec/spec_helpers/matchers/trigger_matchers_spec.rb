require 'spec_helper'

describe 'Trigger Matchers' do

  class TriggerSpecProductController < WebsocketRails::BaseController

    # a method that does not trigger messages
    def update_product
    end

    def delete_product
      data = message[:data] ? 'Return Data' : nil
      if message[:confirm_delete]
        trigger_success(data)
      else
        trigger_failure(data)
      end
    end

  end

  def define_test_events
    WebsocketRails.config.route_block = nil
    WebsocketRails::EventMap.describe do

      namespace :product do
        subscribe :update, :to => TriggerSpecProductController, :with_method => :update_product
        subscribe :delete, :to => TriggerSpecProductController, :with_method => :delete_product
      end
    end
  end

  before { define_test_events }

  # as we have have 16 possible combinations of trigger messages and data matching pattern (data|no_data, success|failure,
  # no_checking|checking_with_any|checking_with_nil|checking_with_exact_data) plus the case of no message at all
  # for EACH of the matchers, resulting in a total 51 cases, we will not extensively test all cases for all matchers
  # but we just make sure that coverage is 100%

  describe 'trigger_message' do

    it 'should return false when the event does not trigger any message' do
      expect(create_event('product.update', nil).dispatch).not_to trigger_message
    end

    it 'should produce the correct failure message when no trigger is generated' do
      event = create_event('product.update', nil).dispatch
      matcher = trigger_message
      matcher.instance_variable_set('@actual', event)
      expect(matcher.failure_message).to eq 'expected product.update to trigger message, instead it did not trigger any message'
    end

    it 'should return true when the message is a failure' do
      expect(create_event('product.delete', {confirm_delete: false, data: true}).dispatch).to trigger_message
    end

    it 'should return true when the message is a success' do
      expect(create_event('product.delete', {confirm_delete: true, data: false})).to satisfy{|e| trigger_message e.data}
    end

    context 'when a message is triggered with no data' do

      it 'should return true when no check is done' do
        expect(create_event('product.delete', {confirm_delete: true, data: false})).to satisfy{|e| trigger_message e.data}
      end

      it 'should produce the correct negative failure message when no check on data is done' do
        event = create_event('product.delete', {confirm_delete: true, data: false}).dispatch
        matcher = trigger_message
        matcher.instance_variable_set('@actual', event)
        expect(matcher.failure_message_when_negated).to eq 'expected product.delete not to trigger message'
      end

      it 'should return true when explicitly checking no data' do
        expect(create_event('product.delete', {confirm_delete: false, data: false}).dispatch).to trigger_message :nil
      end

      it 'should produce the correct negative failure message when explicitly checking no data' do
        event = create_event('product.delete', {confirm_delete: true, data: false}).dispatch
        matcher = trigger_message :nil
        matcher.instance_variable_set('@actual', event)
        expect(matcher.failure_message_when_negated).to eq 'expected product.delete not to trigger message with no data'
      end

      it 'should return false when checking for some data' do
        expect(create_event('product.delete', {confirm_delete: true, data: false}).dispatch).not_to trigger_message :any
      end

      it 'should return the correct failure message when checking for some data' do
        event = create_event('product.delete', {confirm_delete: true, data: false}).dispatch
        matcher = trigger_message :any
        matcher.instance_variable_set('@actual', event)
        expect(matcher.failure_message).to eq 'expected product.delete to trigger message with some data, instead it triggered message with no data'
      end

      it 'should return false when checking for specific data' do
        expect(create_event('product.delete', {confirm_delete: false, data: false}).dispatch).not_to trigger_message 'Expected Data'
      end

      it 'should return the correct failure message when checking for specific data' do
        event = create_event('product.delete', {confirm_delete: true, data: false}).dispatch
        matcher = trigger_message 'Expected Data'
        matcher.instance_variable_set('@actual', event)
        expect(matcher.failure_message).to eq 'expected product.delete to trigger message with data Expected Data, instead it triggered message with no data'
      end

    end

    context 'when a message is triggered with some data' do

      it 'should return true when no check is done' do
        expect(create_event('product.delete', {confirm_delete: true, data: true}).dispatch).to trigger_message
      end

      it 'should return false when explicitly checking no data' do
        expect(create_event('product.delete', {confirm_delete: false, data: true}).dispatch).not_to trigger_message :nil
      end

      it 'should produce the correct failure message when explicitly checking for no data' do
        event = create_event('product.delete', {confirm_delete: false, data: true}).dispatch
        matcher = trigger_message :nil
        matcher.instance_variable_set('@actual', event)
        expect(matcher.failure_message).to eq 'expected product.delete to trigger message with no data, instead it triggered message with data Return Data'
      end

      it 'should return true when checking for some data' do
        expect(create_event('product.delete', {confirm_delete: true, data: true}).dispatch).to trigger_message :any
      end

      it 'should produce the correct negative failure message when checking for some data' do
        event = create_event('product.delete', {confirm_delete: false, data: true}).dispatch
        matcher = trigger_message :any
        matcher.instance_variable_set('@actual', event)
        expect(matcher.failure_message_when_negated).to eq 'expected product.delete not to trigger message with some data'
      end

      it 'should return false when checking for specific data with wrong data' do
        expect(create_event('product.delete', {confirm_delete: false, data: true}).dispatch).not_to trigger_message 'Wrong Data'
      end

      it 'should produce the correct failure message when checking for specific data' do
        event = create_event('product.delete', {confirm_delete: false, data: true}).dispatch
        matcher = trigger_message 'Wrong Data'
        matcher.instance_variable_set('@actual', event)
        expect(matcher.failure_message).to eq 'expected product.delete to trigger message with data Wrong Data, instead it triggered message with data Return Data'
      end

      it 'should return true when checking for specific data with correct data' do
        expect(create_event('product.delete', {confirm_delete: true, data: true}).dispatch).to trigger_message 'Return Data'
      end

      it 'should produce the correct negative failure message when checking for specific data' do
        event = create_event('product.delete', {confirm_delete: false, data: true}).dispatch
        matcher = trigger_message 'Return Data'
        matcher.instance_variable_set('@actual', event)
        expect(matcher.failure_message_when_negated).to eq 'expected product.delete not to trigger message with data Return Data'
      end

    end

    it 'should produce the correct description' do
      event = create_event('product.update', nil).dispatch
      matcher = trigger_message 'Return Data'
      matcher.instance_variable_set('@actual', event)
      expect(matcher.description).to eq 'trigger message with data Return Data'
    end


  end

  describe 'trigger_success_message' do

    it 'should return false when the method does not trigger any message' do
      expect(create_event('product.update', nil).dispatch).not_to trigger_success_message
    end

    it 'should produce the correct failure message when the method does not trigger any message' do
      event = create_event('product.update', nil).dispatch
      matcher = trigger_success_message 'Return Data'
      matcher.instance_variable_set('@actual',event)
      expect(matcher.failure_message).to eq 'expected product.update to trigger success message with data Return Data, instead it did not trigger any message'
    end

    it 'should return true when the method triggers a success message' do
      expect(create_event('product.delete', {confirm_delete: true, data: true}).dispatch).to trigger_success_message
    end

    it 'should produce the correct negative failure message when the method triggers a success message' do
      event = create_event('product.delete', {confirm_delete: true, data: true}).dispatch
      matcher = trigger_success_message :any
      matcher.instance_variable_set('@actual',event)
      expect(matcher.failure_message_when_negated).to eq 'expected product.delete not to trigger success message with some data'
    end

    it 'should return false when the method triggers a failure message' do
      expect(create_event('product.delete', {confirm_delete: false, data: true}).dispatch).not_to trigger_success_message
    end

    it 'should produce the correct failure message when the method triggers a failure message' do
      event = create_event('product.delete', {confirm_delete: false, data: true}).dispatch
      matcher = trigger_success_message
      matcher.instance_variable_set('@actual',event)
      expect(matcher.failure_message).to eq 'expected product.delete to trigger success message, instead it triggered a failure message with data Return Data'
    end

  end

  describe 'trigger_failure_message' do

    it 'should return false when the method does not trigger any message' do
      expect(create_event('product.update', nil).dispatch).not_to trigger_failure_message
    end

    it 'should produce the correct failure message when the method does not trigger any message' do
      event = create_event('product.update', nil).dispatch
      matcher = trigger_failure_message 'Return Data'
      matcher.instance_variable_set('@actual',event)
      expect(matcher.failure_message).to eq 'expected product.update to trigger failure message with data Return Data, instead it did not trigger any message'
    end

    it 'should return false when the method triggers a success message' do
      expect(create_event('product.delete', {confirm_delete: true, data: true}).dispatch).not_to trigger_failure_message
    end

    it 'should produce the correct failure message when the method triggers a success message' do
      event = create_event('product.delete', {confirm_delete: true, data: false}).dispatch
      matcher = trigger_failure_message :any
      matcher.instance_variable_set('@actual',event)
      expect(matcher.failure_message).to eq 'expected product.delete to trigger failure message with some data, instead it triggered a success message with no data'
    end


    it 'should return true when the method triggers a failure message' do
      expect(create_event('product.delete', {confirm_delete: false, data: true}).dispatch).to trigger_failure_message
    end

    it 'should produce the correct negative failure message when the method triggers a failure message' do
      event = create_event('product.delete', {confirm_delete: false, data: true}).dispatch
      matcher = trigger_failure_message
      matcher.instance_variable_set('@actual',event)
      expect(matcher.failure_message_when_negated).to eq 'expected product.delete not to trigger failure message'
    end

  end

end
