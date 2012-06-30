require 'spec_helper'

module WebsocketRails
  describe Channel do
    subject { Channel.new :awesome_channel }

    let(:connection) { double('connection') }

    before do
      connection.stub!(:trigger)
    end

    it "should maintain a pool of subscribed connections" do
      subject.subscribers.should == []
    end

    describe "#subscribe" do
      it "should add the connection to the subscriber pool" do
        subject.subscribe connection
        subject.subscribers.include?(connection).should be_true
      end
    end

    describe "#trigger" do
      it "should create a new event and trigger it on all subscribers" do
        event = double('event').as_null_object
        Event.should_receive(:new) do |name,data,options|
          name.should == 'event'
          data.should == 'data'
          options.should be_a Hash
          event
        end
        connection.should_receive(:trigger).with(event)
        subject.subscribe connection
        subject.trigger 'event', 'data'
      end
    end

    describe "#trigger_event" do
      it "should forward the event to the subscribers" do
        subject.should_receive(:send_data).with('event')
        subject.trigger_event 'event'
      end
    end
  end
end
