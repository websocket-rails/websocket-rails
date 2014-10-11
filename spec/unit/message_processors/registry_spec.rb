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
        expect(subject.dispatcher).to eq(dispatcher)
      end

      it "provides access to the processor registry" do
        expect(subject.processors.include?(TestRegistry)).to be true
      end

      describe "#init_processors!" do
        it "creates new instances of each message processor" do
          expect(TestRegistry).to receive(:new).and_call_original
          subject.init_processors!
        end

        it "stores the instantiated processors" do
          subject.init_processors!
          processor = subject.ready_processors.first
          expect(processor).to be_a TestRegistry
        end

        it "sets the global dispatcher on all processors" do
          subject.init_processors!
          processor = subject.ready_processors.first
          expect(processor.dispatcher).to eq(dispatcher)
        end

        it "tells each processor to begin processing their inbound message queue" do
          expect_any_instance_of(TestRegistry).to receive(:process_inbound)
          subject.init_processors!
        end

        it "returns a reference to itself" do
          expect(subject.init_processors!).to eq(subject)
        end
      end

    end
  end
end
