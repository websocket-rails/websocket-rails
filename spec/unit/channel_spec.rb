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
      it "should trigger an event when subscriber joins" do
        subject.should_receive(:trigger).with("subscriber_join")
        subject.subscribe connection
      end

      it "should add the connection to the subscriber pool" do
        subject.subscribe connection
        subject.subscribers.include?(connection).should be_true
      end
    end

    describe "#unsubscribe" do
      it "should remove connection from subscriber pool" do
        subject.subscribe connection
        subject.unsubscribe connection
        subject.subscribers.include?(connection).should be_false
      end

      it "should do nothing if connection is not subscribed to channel" do
        subject.unsubscribe connection
        subject.subscribers.include?(connection).should be_false
      end

      it "should trigger an event when subscriber parts" do
        subject.subscribers << connection
        subject.should_receive(:trigger).with('subscriber_part')
        subject.unsubscribe connection
      end
    end

    describe "#trigger" do
      it "should create a new event and trigger it on all subscribers" do
        event = double('event').as_null_object
        Event.should_receive(:new) do |name,options|
          name.should == 'event'
          options[:data].should == 'data'
          event
        end
        connection.should_receive(:trigger).with(event)
        subject.subscribers << connection
        subject.trigger 'event', 'data'
      end
    end

    describe "#trigger_event" do
      it "should forward the event to the subscribers" do
        event = double('event').as_null_object
        subject.should_receive(:send_data).with(event)
        subject.trigger_event event
      end
    end

    context "private channels" do
      before do
        subject.subscribers << connection
      end

      it "should be public by default" do
        subject.instance_variable_get(:@private).should_not be_true
      end

      describe "#make_private" do
        it "should set the @private instance variable to true" do
          subject.make_private
          subject.instance_variable_get(:@private).should be_true
        end

        context "when Configuration#keep_subscribers_when_private? is false" do
          it "should clear any existing subscribers in the channel" do
            subject.subscribers.count.should == 1
            subject.make_private
            subject.subscribers.count.should == 0
          end
        end

        context "when Configuration#keep_subscribers_when_private? is true" do
          before do
            WebsocketRails.config.keep_subscribers_when_private = true
          end

          it "should leave the existing subscribers in the channel" do
            subject.subscribers.count.should == 1
            subject.make_private
            subject.subscribers.count.should == 1
          end
        end
      end

      describe "#is_private?" do
        it "should return true if the channel is private" do
          subject.instance_variable_set(:@private,true)
          subject.is_private?.should be_true
        end

        it "should return false if the channel is public" do
          subject.instance_variable_set(:@private,false)
          subject.is_private?.should_not be_true
        end
      end
    end
  end
end
