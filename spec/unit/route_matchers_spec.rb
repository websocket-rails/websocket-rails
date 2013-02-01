require 'spec_helper'

# The specs in this file are not strictly testing the library functionality
# but rather giving an example on how to test the event routing
# in your Rails application

class ProductController < WebsocketRails::BaseController

  def update_product
    true
  end

  def delete_product
    true
  end

end

class WarehouseController < WebsocketRails::BaseController

  def remove_product
    true
  end

end


# These specs are not strictly testing the library functionality
# but rather giving an example on how to test the event routing and controllers
# in your Rails application

describe 'events' do

  def define_test_events
    WebsocketRails.route_block = nil
    WebsocketRails::EventMap.describe do

      namespace :product do
        subscribe :update, :to => ProductController, :with_method => :update_product
        subscribe :delete, :to => ProductController, :with_method => :delete_product
        subscribe :delete, :to => WarehouseController, :with_method => :remove_product
      end
    end
  end

  before { define_test_events }

  describe 'product.update' do

    let(:event) { create_event('product.update', nil)}

    it 'should be routed to the correct controller' do
      event.should be_routed_to 'product#update_product'
    end

    it 'should ONLY be routed to the correct controller' do
      event.should be_routed_only_to to: ProductController, with_method: :update_product
    end

    it 'should not be routed to the wrong controller' do
      event.should_not be_routed_to to: WarehouseController, with_method: :remove_product
    end

  end

  describe 'product.delete' do

    let(:event) { create_event('product.delete', nil)}

    it 'should be routed to the correct controller' do
      event.should be_routed_to 'product#delete_product'
      event.should be_routed_to to: WarehouseController, with_method: :remove_product
    end

    it 'should NOT be routed ONLY to one controller' do
      event.should_not be_routed_only_to 'product#delete_product'
    end

    it 'should not be routed to the wrong controller' do
      event.should_not be_routed_to 'product#update_product'
    end

  end




end