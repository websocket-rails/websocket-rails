require 'spec_helper'

module WebsocketRails
  describe EventQueue do

    describe "#initialize" do
      it "should create an empty queue" do
        subject.queue.should == []
      end
    end

    describe "#<<" do
      it "should add the item to the queue" do
        subject << 'event'
        subject.queue.should == ['event']
      end
    end

    describe "#flush" do
      before do
        subject.queue << 'event'
      end

      it "should yield all items in the queue" do
        subject.flush do |event|
          event.should == 'event'
        end
      end

      it "should empty the queue" do
        subject.flush
        subject.queue.should == []
      end
    end
  end
end
