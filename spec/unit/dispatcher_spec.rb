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
      expect(subject.message_queue).to be_a EventQueue
    end

    it "creates a new instance of the MessageProcessor Registry" do
      expect(subject.processor_registry).to be_a MessageProcessors::Registry
    end

    describe "#dispatch" do
      it "enqueus an event for processing" do
        expect(subject.message_queue).to receive(:<<).with message
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
        @processor = double('MessageProcessor')
        allow(@processor).to receive(:process_message).and_return true
        allow(subject.processor_registry).to receive(:processors_for).and_return [@processor]

        subject.message_queue << message
      end

      it "pops the first message off the queue" do
        subject.process_inbound
        sleep(0.1)
        expect(subject.message_queue.size).to eq(0)
      end

      it "executes process_message on the appropriate processor" do
        subject.process_inbound
        sleep(0.1)
        expect(@processor).to have_received(:process_message).with(message)
      end

    end

    describe "#broadcast_message" do
      before do
        allow(connection_manager).to receive(:connections).and_return({"connection_id" => connection})
        @event = Event.deserialize(encoded_message, connection)
      end

      it "should send a message to all connected clients" do
        expect(connection).to receive(:trigger).with(@event)
        subject.broadcast_message @event
      end
    end

  end
end
