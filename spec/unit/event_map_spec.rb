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
      
      it "should initialize empty hashes for classes and events" do
        subject.evaluate Proc.new {}
        subject.classes.should == {}
        subject.events.should == {}
      end
    end
    
    context "#subscribe" do
      before(:each) { define_test_events }
      
      it "should store the event in the events hash" do
        subject.events.has_key?(:client_connected).should be_true
      end
      
      it "should store the instantiated controller in the classes hash" do
        subject.classes[Object].class.should == Object
      end
      
      it "should set the dispatcher on the instantiated controller" do
        subject.classes[Object].instance_variable_get(:@_dispatcher).should == dispatcher
      end
      
      it "should store the class constant and method name in the events hash" do
        subject.events[:client_connected].should == [[Object,:object_id]]
      end
    end
    
    context "#routes_for" do
      before(:each) { define_test_events }
      
      it "should yield the class constant and method symbol for each route defined for an event" do
        subject.routes_for(:client_connected) do |controller,method|
          controller.class.should == Object
          method.should == :object_id
        end
      end
    end
    
  end
end
