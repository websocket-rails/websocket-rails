require 'spec_helper'

module WebsocketRails
  describe EventQueue do

    describe "#initialize" do
      it "should create an empty queue" do
        expect(subject.queue).to be_a(Queue)
      end
    end

    describe "#<<" do
      it "should add the item to the queue" do
        subject << 'event'
        expect(subject.queue.pop).to eq('event')
      end
    end

    describe "#flush" do
      before do
        subject.queue << 'event'
      end

      it "should yield all items in the queue" do
        subject.flush do |event|
          expect(event).to eq('event')
        end
      end

      it "should empty the queue" do
        subject.flush
        expect(subject.queue).to eq([])
      end
    end
  end
end
