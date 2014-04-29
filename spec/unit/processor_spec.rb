require "spec_helper"

module WebsocketRails
  describe Processor do

    class TestProcessor
      include Processor
    end

    subject { TestProcessor.new }

    it "registers itself with the MessageProcessor Registry" do
      MessageProcessors::Registry.processors.include?(TestProcessor).should be_true
    end

    before do
      MessageProcessors::Registry.processors = [TestProcessor]
    end

    after do
      MessageProcessors::Registry.processors.clear
    end

    it "provides access to the global Channel Manager" do
      subject.channel_manager.should be_a ChannelManager
    end

    it "provides access to the global Synchronization system" do
      subject.sync.should be_a Synchronization::Synchronize
    end

    context "dispatcher delegation" do
      before do
        @dispatcher = double(Dispatcher)
        subject.dispatcher = @dispatcher
      end

      it "delegates #event_map to dispatcher" do
        @dispatcher.should_receive(:event_map)
        subject.event_map
      end

      it "delegates #controller_factory to dispatcher" do
        @dispatcher.should_receive(:controller_factory)
        subject.controller_factory
      end

      it "delegates #reload_event_map! to dispatcher" do
        @dispatcher.should_receive(:reload_event_map!)
        subject.reload_event_map!
      end

      it "delegates #broadcast_message to dispatcher" do
        @dispatcher.should_receive(:broadcast_message)
        subject.broadcast_message
      end

      it "delegates #filtered_channels to WebsocketRails" do
        WebsocketRails.should_receive(:filtered_channels)
        subject.filtered_channels
      end
    end

    it "provides an inbound message queue" do
      subject.message_queue.should be_a EM::Queue
    end

    let(:message) { double(Message).as_null_object }

    describe "#process_inbound" do
      before do
        subject.should_receive(:process_message).with(message)
        subject.message_queue << message
      end

      it "pops the first message off the queue" do
        subject.process_inbound
        subject.message_queue.size.should == 0
      end

      it "schedules the #process_inbound method for the next reactor tick" do
        subject.should_receive(:process_inbound).twice.and_call_original
        subject.process_inbound
      end
    end

    describe "#process_message" do
      it "should be implemented in the appropriate processor" do
        expect{ subject.process_message(:test) }.to raise_exception(NotImplementedError)
      end
    end

  end
end
