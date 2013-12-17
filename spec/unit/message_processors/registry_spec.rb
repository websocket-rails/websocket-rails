require "spec_helper"

module WebsocketRails
  module MessageProcessors
    describe Registry do

      class TestRegistry
        include WebsocketRails::Processor
      end

      let(:dispatcher) { double(Dispatcher).as_null_object }

      subject { Registry.new(dispatcher) }

      before do
        Registry.processors = [TestRegistry]
      end

      after do
        Registry.processors.clear
      end

      it "stores a reference to the global dispatcher" do
        subject.dispatcher.should == dispatcher
      end

      it "provides access to the processor registry" do
        subject.processors.include?(TestRegistry).should be_true
      end

      describe "#init_processors!" do
        it "creates new instances of each message processor" do
          TestRegistry.should_receive(:new).and_call_original
          subject.init_processors!
        end

        it "stores the instantiated processors" do
          subject.init_processors!
          processor = subject.ready_processors.first
          processor.should be_a TestRegistry
        end

        it "sets the global dispatcher on all processors" do
          subject.init_processors!
          processor = subject.ready_processors.first
          processor.dispatcher.should == dispatcher
        end

        it "tells each processor to begin processing their inbound message queue" do
          TestRegistry.any_instance.should_receive(:process_inbound)
          subject.init_processors!
        end

        it "returns a reference to itself" do
          subject.init_processors!.should == subject
        end
      end

    end
  end
end
