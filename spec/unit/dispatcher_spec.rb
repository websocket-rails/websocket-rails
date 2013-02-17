require 'spec_helper'
require 'support/mock_web_socket'

module WebsocketRails

  class EventTarget
    attr_reader :_event, :_dispatcher, :test_method

    def initialize_session
      true
    end

    def execute_observers(event_name)
      true
    end
  end

  describe Dispatcher do

    let(:event) { double('Event') }
    let(:connection) { MockWebSocket.new }
    let(:connection_manager) { double('connection_manager').as_null_object }
    subject { Dispatcher.new(connection_manager) }

    describe "#receive_encoded" do
      context "receiving a new message" do
        before do
          Event.stub(:new_from_json).and_return( event )
        end

        it "should be decoded from JSON and dispatched" do
          subject.stub(:dispatch) do |dispatch_event|
            dispatch_event.should == event
          end
          subject.receive_encoded(encoded_message,connection)
        end
      end
    end

    describe "#receive" do
      before { Event.stub(:new).and_return( event ) }
      it "should dispatch a new event" do
        subject.stub(:dispatch) do |dispatch_event|
          dispatch_event.should == event
        end
        subject.receive(:test_event,{},connection)
      end
    end

    context "dispatching an event" do
      before do
        EventMap.any_instance.stub(:routes_for).with(any_args).and_yield(EventTarget, :test_method)
        event.stub(:name).and_return(:test_method)
        event.stub(:data).and_return(:some_message)
        event.stub(:connection).and_return(connection)
        event.stub(:is_channel?).and_return(false)
        event.stub(:is_invalid?).and_return(false)
      end

      it "should execute the correct method on the target class" do
        EventTarget.any_instance.should_receive(:test_method)
        subject.dispatch(event)
      end

      context "channel events" do
        it "should forward the data to the correct channel" do
          event = Event.new 'test', :data => 'data', :channel => :awesome_channel
          channel = double('channel')
          channel.should_receive(:trigger_event).with(event)
          WebsocketRails.should_receive(:[]).with(:awesome_channel).and_return(channel)
          subject.dispatch event
        end
      end

      context "invalid events" do
        before do
          event.stub(:is_invalid?).and_return(true)
        end

        it "should not dispatch the event" do
          subject.should_not_receive(:route)
          subject.dispatch(event)
        end
      end
    end

    describe "#send_message" do
      before do
        @event = Event.new_from_json( encoded_message, connection )
      end

      it "should send a message to the event's connection object" do
        connection.should_receive(:trigger).with(@event)
        subject.send_message @event
      end
    end

    describe "#broadcast_message" do
      before do
        connection_manager.stub(:connections).and_return([connection])
        @event = Event.new_from_json( encoded_message, connection )
      end

      it "should send a message to all connected clients" do
        connection.should_receive(:trigger).with(@event)
        subject.broadcast_message @event
      end
    end
  end
end
