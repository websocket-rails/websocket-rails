require 'spec_helper'

# this classes are outside the WebsocketRails namespace to better reflect the actual
# situation in a normal usage

class ProductController < WebsocketRails::BaseController
  def update_product
    true
  end
end

# name is chosen so that we know camelize is working correctly
class ComplexProductController < WebsocketRails::BaseController

  def simplify_product
    true
  end

end


module WebsocketRails
  describe EventMap do


    def define_test_events
      WebsocketRails.route_block = nil
      WebsocketRails::EventMap.describe do
        subscribe :client_connected, :to => ChatController, :with_method => :new_user

        namespace :product do
          subscribe :update, :to => ProductController, :with_method => :update_product
        end

        namespace :complex_product do
          subscribe :simplify, 'complex_product#simplify'
        end

      end
    end
    
    let(:dispatcher) { double('dispatcher').as_null_object }
    subject { EventMap.new(dispatcher) }
    before { define_test_events }

    context "EventMap.describe" do
      it "should store the event route block in the global configuration" do
        WebsocketRails.route_block.should be_present
      end
    end
    
    context "Events in the global namespace" do
      
      it "should store the event in the correct namespace" do
        subject.namespace.actions[:client_connected].should be_present
        subject.namespace.name.should == :global
      end
      
      it "should store the instantiated controller in the classes hash" do
        subject.namespace.controllers[ChatController].class.should == ChatController
      end
      
      it "should set the dispatcher on the instantiated controller" do
        subject.namespace.controllers[ChatController].instance_variable_get(:@_dispatcher).should == dispatcher
      end
      
      it "should store the class constant and method name in the events hash" do
        subject.namespace.actions[:client_connected].should == [[ChatController,:new_user]]
      end

    end

    context "Events in a child namespace" do

      before { @namespace = subject.namespace }
      
      it "should store the event in the correct namespaces" do
        @namespace.namespaces[:product].actions[:update].should be_present
        @namespace.namespaces[:complex_product].actions[:simplify].should be_present
      end
      
    end

    context "#routes_for" do

      let(:event) { double('event') }
      
      context "with events in the global namespace" do
        it "should yield the controller and action name for each route defined for an event" do
          event.stub(:name).and_return(:client_connected)
          event.stub(:namespace).and_return([:global])

          subject.routes_for(event) do |controller,method|
            controller.class.should == ChatController
            method.should == :new_user
          end
        end
      end

      context "with events in a child namespace" do
        it "should yield the controller and action name for each route defined with a hash for an event" do
          ProductController.any_instance.should_receive(:action_executed)
          event = HelperMethods::MockEvent.new :update, [:global,:product]
          
          subject.routes_for(event) do |controller,method|
            controller.action_executed
            controller.class.should == ProductController
            method.should == :update_product
          end

        end

        it "should yield the controller and action name for each route defined with a string for an event" do
          ComplexProductController.any_instance.should_receive(:action_executed)
          event = HelperMethods::MockEvent.new :simplify, [:global,:complex_product]

          subject.routes_for(event) do |controller,method|
            controller.action_executed
            controller.class.should == ComplexProductController
            method.should == :simplify
          end

        end

      end

    end

  end
end
