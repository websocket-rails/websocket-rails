require 'spec_helper'

module WebsocketRails

  class EventTarget
    attr_reader :_event, :_dispatcher, :test_method, :catch_all_method
  end

  describe Dispatcher do

    let(:message) { double(Message).as_null_object }
    let(:connection) { MockWebSocket.new }
    let(:connection_manager) { double('connection_manager').as_null_object }
    subject { Dispatcher.new(connection_manager) }

    it "exposes an inbound message queue" do
      subject.message_queue.should be_a EM::Queue
    end

    it "creates a new instance of the MessageProcessor Registry" do
      subject.processor_registry.should be_a MessageProcessors::Registry
    end

    describe "#dispatch" do
      it "enqueus an event for processing" do
        subject.message_queue.should_receive(:<<).with message
        subject.dispatch(message)
      end

      context "invalid events" do
        before do
          #event.stub(:is_invalid?).and_return(true)
        end
      end
    end

    describe "#process_inbound" do
      before do
        @message_queue = []
        @processor = double('MessageProcessor')
        @processor.stub(:message_queue).and_return @message_queue
        subject.processor_registry.stub(:processors_for).and_return [@processor]

        subject.message_queue << message
      end

      it "pops the first message off the queue" do
        subject.process_inbound
        subject.message_queue.size.should == 0
      end

      it "places the message in the appropriate processor queue" do
        subject.process_inbound
        @message_queue.pop.should == message
      end

      it "schedules the #process_inbound method for the next reactor tick" do
        subject.should_receive(:process_inbound).twice.and_call_original
        subject.process_inbound
      end
    end

    describe "#broadcast_message" do
      before do
        connection_manager.stub(:connections).and_return({"connection_id" => connection})
        @event = Event.deserialize(encoded_message, connection)
      end

      it "should send a message to all connected clients" do
        connection.should_receive(:trigger).with(@event)
        subject.broadcast_message @event
      end
    end

  end
end
