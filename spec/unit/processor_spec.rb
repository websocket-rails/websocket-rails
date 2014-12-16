require "spec_helper"

module WebsocketRails
  describe Processor do

    class TestProcessor
      include Processor
    end

    subject { TestProcessor.new }

    it "registers itself with the MessageProcessor Registry" do
      expect(MessageProcessors::Registry.processors.include?(TestProcessor)).to be true
    end

    before do
      MessageProcessors::Registry.processors = [TestProcessor]
    end

    after do
      MessageProcessors::Registry.processors.clear
    end

    it "provides access to the global Channel Manager" do
      expect(subject.channel_manager).to be_a ChannelManager
    end

    it "provides access to the global Synchronization system" do
      expect(subject.sync).to be_a Synchronization::Synchronize
    end

    context "dispatcher delegation" do
      before do
        @dispatcher = double(Dispatcher)
        subject.dispatcher = @dispatcher
      end

      it "delegates #event_map to dispatcher" do
        expect(@dispatcher).to receive(:event_map)
        subject.event_map
      end

      it "delegates #controller_factory to dispatcher" do
        expect(@dispatcher).to receive(:controller_factory)
        subject.controller_factory
      end

      it "delegates #reload_event_map! to dispatcher" do
        expect(@dispatcher).to receive(:reload_event_map!)
        subject.reload_event_map!
      end

      it "delegates #broadcast_message to dispatcher" do
        expect(@dispatcher).to receive(:broadcast_message)
        subject.broadcast_message
      end

      it "delegates #filtered_channels to WebsocketRails" do
        expect(WebsocketRails).to receive(:filtered_channels)
        subject.filtered_channels
      end
    end

    let(:message) { double(Message).as_null_object }

    describe "#process_message" do
      it "should be implemented in the appropriate processor" do
        expect{ subject.process_message(:test) }.to raise_exception(NotImplementedError)
      end
    end

  end
end
