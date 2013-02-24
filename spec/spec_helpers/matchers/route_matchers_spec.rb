require 'spec_helper'

describe 'Route Matchers' do

  class RouteSpecProductController < WebsocketRails::BaseController

    def update_product
    end

    def delete_product
    end

  end

  class RouteSpecWarehouseController < WebsocketRails::BaseController

    def remove_product
    end

  end

  def define_route_test_events
    WebsocketRails.config.route_block = nil
    WebsocketRails::EventMap.describe do

      namespace :product do
        subscribe :update, :to => RouteSpecProductController, :with_method => :update_product
        subscribe :delete, :to => RouteSpecProductController, :with_method => :delete_product
        subscribe :delete, :to => RouteSpecWarehouseController, :with_method => :remove_product
      end
    end
  end

  before { define_route_test_events }

  describe 'be_routed_to' do

    it 'should return true when the event is routed only to the specified controller' do
     create_event('product.update', nil).should be_routed_to 'route_spec_product#update_product'
    end

    it 'should return true when the event is routed also to the specified controller' do
     create_event('product.delete', nil).should be_routed_to 'route_spec_product#delete_product'
    end

    it 'should return false when the event is not routed to the specified controller' do
      create_event('product.update', nil).should_not be_routed_to 'route_spec_product#delete_product'
    end

    it 'should produce the correct failure message' do
      event = create_event('route_spec_product.update', nil)
      matcher = be_routed_to 'route_spec_product#delete_product'
      cache_messages_for_matcher(matcher, event)
      matcher.should produce_as_failure_message 'expected event update to be routed to target route_spec_product#delete_product'
    end

    it 'should produce the correct negative failure message' do
      event = create_event('product.update', nil)
      matcher = be_routed_to 'route_spec_product#update_product'
      cache_messages_for_matcher(matcher, event)
      matcher.should produce_as_negative_failure_message 'expected event update not to be routed to target route_spec_product#update_product'
    end

    it 'should produce the correct description' do
      event = create_event('product.update', nil)
      matcher = be_routed_to 'route_spec_product#update_product'
      cache_messages_for_matcher(matcher, event)
      matcher.should produce_as_description 'be routed to target route_spec_product#update_product'
    end

  end

  describe 'be_routed_only_to' do

    it 'should return true when the event is routed only to the specified controller' do
     create_event('product.update', nil).should be_routed_only_to 'route_spec_product#update_product'
    end

    it 'should return false when the event is routed also to the specified controller' do
     create_event('product.delete', nil).should_not be_routed_only_to 'route_spec_product#delete_product'
    end

    it 'should return false when the event is not routed to the specified controller' do
      create_event('product.update', nil).should_not be_routed_only_to 'route_spec_product#delete_product'
    end

    it 'should produce the correct failure message' do
      event = create_event('product.update', nil)
      matcher = be_routed_only_to 'route_spec_product#delete_product'
      cache_messages_for_matcher(matcher, event)
      matcher.should produce_as_failure_message 'expected event update to be routed only to target route_spec_product#delete_product'
    end

    it 'should produce the correct negative failure message' do
      event = create_event('product.update', nil)
      matcher = be_routed_only_to 'route_spec_product#update_product'
      cache_messages_for_matcher(matcher, event)
      matcher.should produce_as_negative_failure_message 'expected event update not to be routed only to target route_spec_product#update_product'
    end

    it 'should produce the correct description' do
      event = create_event('product.update', nil)
      matcher = be_routed_only_to 'route_spec_product#update_product'
      cache_messages_for_matcher(matcher, event)
      matcher.should produce_as_description 'be routed only to target route_spec_product#update_product'
    end

  end
end
