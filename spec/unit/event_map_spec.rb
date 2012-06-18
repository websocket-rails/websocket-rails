require 'spec_helper'

module WebsocketRails
  describe EventMap do
    
    def define_test_events
      WebsocketRails.route_block = nil
      WebsocketRails::EventMap.describe do
        subscribe :client_connected, to: Object, with_method: :object_id
      end
    end
    
    let(:dispatcher) { double('dispatcher').as_null_object }
    subject { EventMap.new(dispatcher) }
    
    context "EventMap.describe" do
      it "should store the event route block in the global configuration" do
        define_test_events
        WebsocketRails.route_block.should be_present
      end
    end
    
    context "#evaluate" do
      it "should evaluate the route DSL" do
        evaluated = double()
        evaluated.should_receive(:done)
        block = Proc.new { evaluated.done }
        subject.evaluate( block )
      end
      
      it "should initialize an empty hash for classes" do
        subject.evaluate Proc.new {}
        subject.classes.should == {}
      end

      it "should initialize a hash primed with new EventMap::Events instances for namespaced events" do
        subject.evaluate Proc.new {}
        subject.events[:global].class.should == EventMap::Events
      end

      it "should set the current namespace to :global" do
        subject.evaluate Proc.new {}
        subject.current_namespace.should == :global
      end
    end
    
    context "#subscribe" do
      before(:each) { define_test_events }
      
      it "should store the event in the correct namespace" do
        subject.events[:global].has_key?(:client_connected).should be_true
      end
      
      it "should store the instantiated controller in the classes hash" do
        subject.classes[Object].class.should == Object
      end
      
      it "should set the dispatcher on the instantiated controller" do
        subject.classes[Object].instance_variable_get(:@_dispatcher).should == dispatcher
      end
      
      it "should store the class constant and method name in the events hash" do
        subject.events[:global][:client_connected].should == [[Object,:object_id]]
      end
    end

    context "#namespace" do
      it "should set the current_namespace before evaluating the block" do
        subject.namespace :scoped do
          current_namespace.should == :scoped
        end
      end

      it "should restore the global namespace after evaluating the block" do
        subject.namespace :scoped do
          true
        end
        subject.current_namespace.should == subject.global_namespace
      end

      it "should store subscribed events in the correct namespace" do
        subject.namespace :scoped do
          subscribe :new_event, to: ChatController, with_method: :scoped_chat
        end
        subject.events[:scoped][:new_event].should == [[ChatController,:scoped_chat]]
      end
    end
    
    context "#routes_for" do
      before(:each) { define_test_events }
      
      it "should yield the instantiated controller and action name for each route defined for an event" do
        subject.routes_for(:client_connected) do |controller,method|
          controller.class.should == Object
          method.should == :object_id
        end
      end
    end

    describe EventMap::Events do

      subject { EventMap::Events.new }
      
      it "should provide access to a Hash primed with new instances of Array" do
        subject[:test].class.should == Array
      end
    end
    
  end
end
