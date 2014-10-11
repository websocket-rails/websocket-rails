require 'spec_helper'

module WebsocketRails
  describe Channel do
    subject { Channel.new :awesome_channel }

    let(:connection) { double('connection') }

    before do
      allow(connection).to receive(:protocol).and_return("")
      allow(connection).to receive(:trigger)
    end

    it "should maintain a pool of subscribed connections" do
      expect(subject.subscribers).to eq([])
    end

    describe "#subscribe" do
      before do
        allow(connection).to receive(:user).and_return({})
        allow(WebsocketRails.config).to receive(:broadcast_subscriber_events?).and_return(true)
      end
      it "should trigger an event when subscriber joins" do
        expect(subject).to receive(:trigger).with("subscriber_join", connection.user)
        subject.subscribe connection
      end

      it "should add the connection to the subscriber pool" do
        subject.subscribe connection
        expect(subject.subscribers.include?(connection)).to be(true)
      end
    end

    describe "#unsubscribe" do
      before do
        allow(connection).to receive(:user).and_return({})
        allow(WebsocketRails.config).to receive(:broadcast_subscriber_events?).and_return(true)
      end
      it "should remove connection from subscriber pool" do
        subject.subscribe connection
        subject.unsubscribe connection
        expect(subject.subscribers.include?(connection)).to be(false)
      end

      it "should do nothing if connection is not subscribed to channel" do
        subject.unsubscribe connection
        expect(subject.subscribers.include?(connection)).to be(false)
      end

      it "should trigger an event when subscriber parts" do
        subject.subscribers << connection
        expect(subject).to receive(:trigger).with('subscriber_part', connection.user)
        subject.unsubscribe connection
      end
    end

    describe "#trigger" do
      it "should create a new event and trigger it on all subscribers" do
        event = double('event').as_null_object
        expect(Event).to receive(:new) do |name, data, options|
          expect(name).to eq('event')
          expect(data).to eq('data')
          event
        end
        expect(connection).to receive(:trigger).with(event)
        subject.subscribers << connection
        subject.trigger 'event', 'data'
      end
    end

    describe "#trigger_event" do
      it "should forward the event to subscribers if token matches" do
        event = Event.new 'awesome_event', nil, {:channel => 'awesome_channel', :token => subject.token}
        expect(subject).to receive(:send_data).with(event)
        subject.trigger_event event
      end

      it "should ignore the event if the token is invalid" do
        event = Event.new 'invalid_event', nil, {:channel => 'awesome_channel', :token => 'invalid_token'}
        expect(subject).to_not receive(:send_data).with(event)
        subject.trigger_event event
      end

      it "should not propagate if event.propagate is false" do
        event = Event.new 'awesome_event', {:channel => 'awesome_channel', :token => subject.token, :propagate => false}
        expect(connection).to_not receive(:trigger)
        subject.subscribers << connection
        subject.trigger_event event
      end
    end

    describe "#filter_with" do
      it "should add the controller to the filtered_channels hash" do
        filter = double('BaseController')
        subject.filter_with(filter)
        expect(subject.filtered_channels[subject.name]).to eq(filter)
      end

      it "should allow setting the catch_all method" do
        filter = double('BaseController')
        subject.filter_with(filter, :some_method)
        expect(subject.filtered_channels[subject.name]).to eq([filter, :some_method])
      end
    end

    context "private channels" do
      before do
        subject.subscribers << connection
      end

      it "should be public by default" do
        expect(subject.instance_variable_get(:@private)).to_not be true
      end

      describe "#make_private" do
        it "should set the @private instance variable to true" do
          subject.make_private
          expect(subject.instance_variable_get(:@private)).to be true
        end

        context "when Configuration#keep_subscribers_when_private? is false" do
          it "should clear any existing subscribers in the channel" do
            expect(subject.subscribers.count).to eq(1)
            subject.make_private
            expect(subject.subscribers.count).to eq(0)
          end
        end

        context "when Configuration#keep_subscribers_when_private? is true" do
          before do
            WebsocketRails.config.keep_subscribers_when_private = true
          end

          it "should leave the existing subscribers in the channel" do
            expect(subject.subscribers.count).to eq(1)
            subject.make_private
            expect(subject.subscribers.count).to eq(1)
          end
        end
      end

      describe "#is_private?" do
        it "should return true if the channel is private" do
          subject.instance_variable_set(:@private,true)
          expect(subject.is_private?).to be(true)
        end

        it "should return false if the channel is public" do
          subject.instance_variable_set(:@private,false)
          expect(subject.is_private?).to_not be(true)
        end
      end

      describe "#token" do
        it 'is long enough' do
          expect(subject.token.length).to be > 10
        end

        it 'remains the same between two call' do
          expect(subject.token).to eq(subject.token)
        end

        it 'is the same for two channels with the same name' do
          expect(subject.token).to eq(Channel.new(subject.name).token)
        end
      end

    end
  end
end
