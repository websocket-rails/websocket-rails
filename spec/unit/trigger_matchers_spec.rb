require 'spec_helper'

# The specs in this file are not strictly testing the library functionality
# but rather giving an example on how to test the WebsocketRails controllers
# in your Rails application

class ProductController < WebsocketRails::BaseController

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

describe 'ProductController' do

  def define_test_events
    WebsocketRails.route_block = nil
    WebsocketRails::EventMap.describe do

      namespace :product do
        subscribe :update, :to => ProductController, :with_method => :update_product
        subscribe :delete, :to => ProductController, :with_method => :delete_product
      end
    end
  end

  before { define_test_events }

  around(:each) do |example|
    EM.run do
      example.run
    end
  end

  after(:each) do
    EM.stop
  end

  describe 'update_product' do

    it 'should not trigger any message' do
      event = create_event('product.update', nil)
      event.dispatch
      event.should_not trigger_message
    end

  end

  describe 'delete_product' do

    context 'when no data is associated with the message' do

      let(:event) {create_event('product.delete', {confirm_delete: true, data: nil}).dispatch}

      it 'should trigger a message with no data check' do
        event.should trigger_message
      end

      it 'should not trigger a message with some data' do
        event.should_not trigger_message :any
      end

      it 'should trigger a message with explicit check of no data' do
        event.should trigger_message :nil
      end

    end

    context 'when data is associated with the message' do

      let(:event) {create_event('product.delete', {confirm_delete: true, data: 'Return Data'}).dispatch}

      it 'should trigger a message with no data check' do
        event.should trigger_message
      end

      it 'should trigger a message with some data' do
        event.should trigger_message :any
      end

      it 'should not trigger a message with the wrong given data' do
        event.should_not trigger_message 'Wrong Data'
      end

      it 'should not trigger a message with explicit check of no data' do
        event.should_not trigger_message :nil
      end

      it 'should trigger a message with the correct given data' do
        event.should trigger_message 'Return Data'
      end

    end

    # all the variations on data checks are available also for trigger_failure_message and trigger_success_message

    context 'when passing data that makes the controller "succeed"' do

      let(:event) {create_event('product.delete', {confirm_delete: true, data: 'Return Data'}).dispatch}

      it 'should trigger a success message' do
        event.should trigger_success_message
      end

      it 'should not trigger a failure message' do
        event.should_not trigger_failure_message
      end

    end

    context 'when passing data that makes the controller "fail"' do

      let(:event) {create_event('product.delete', {confirm_delete: false, data: 'Return Data'}).dispatch}

      it 'should not trigger a success message' do
        event.should_not trigger_success_message
      end

      it 'should trigger a failure message' do
        event.should trigger_failure_message
      end

    end

  end

end