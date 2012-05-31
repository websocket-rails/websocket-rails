require 'spec_helper'
require 'json'

module WebsocketRails
  
  class EventTarget
    attr_reader :_connection, :_message, :test_method
    
    def execute_observers(event_name)
      true
    end    
  end
  
  describe Dispatcher do
    
    let(:connection) { MockWebSocket.new }
    let(:connection_manager) { double('connection_manager').as_null_object }
    subject { Dispatcher.new(connection_manager) }
    
    let(:test_message) { ['new_message',{message: 'this is a message'}] }
    let(:encoded_message) { test_message.to_json }
    
    context "receiving a new message" do
      it "should be decoded from JSON and dispatched" do
        subject.stub(:dispatch) do |event,data,con|
          event.should == 'new_message'
          data['message'].should == 'this is a message'
          con.should == connection
        end
        subject.receive(encoded_message,connection)
      end
    end
    
    context "dispatching a message for an event" do
      before(:each) do
        @target = EventTarget.new
        Events.any_instance.stub(:routes_for).with(any_args).and_yield( EventTarget, :test_method )
        Events.any_instance.stub(:classes).and_return( { EventTarget => @target } )
      end
      
      it "should execute the correct method on the target class" do
        @target.should_receive(:test_method)
        subject.dispatch('test_method',{},connection)
      end
      
      it "should set the _message instance variable on the target object" do
        subject.dispatch('test_method',:some_message,connection)
        @target._message.should == :some_message
      end
      
      it "should set the _connection instance variable on the target object" do
        subject.dispatch('test_method',:some_message,connection)
        @target._connection.should == connection
      end
    end
    
  end
end