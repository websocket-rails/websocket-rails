require 'spec_helper'

module WebsocketRails
  describe ChannelRouter do
    let (:router)           { ChannelRouter.instance }
    let (:unroutable_event) { Event.new 'notchanevent', id: 42 }
    let (:unrouted_event)   { Event.new 'no_action', id: 42, channel: :my_chan}
    let (:simple_event)     { Event.new 'action', id: 42, channel: :my_chan }
    let (:simple_event2)    { Event.new 'noaction', id: 42, channel: :no_chan }
    let (:complex_event)    { Event.new 'chanevent2', id: 42, channel: 'other_chan:foo' }
    let (:complex_event2)   { Event.new 'chanevent2', id: 42, channel: 'other_chan:foo:bar' }

    describe "#controller_name_for" do
      it "returns nil on non-channel events" do
        router.controller_name_for(unroutable_event).should be_nil
      end

      it "returns the channel controller name for this event" do
        router.controller_name_for(simple_event).should eq(:my_chan)
      end

      it "handle static:variable channel names" do
        router.controller_name_for(complex_event).should eq(:other_chan)
      end
    end

    describe "#controller_class_for" do
      it "returns the controller class for this event" do
        router.controller_class_for(simple_event).should be(Channels::MyChanController)
        router.controller_class_for(complex_event).should be(Channels::OtherChanController)
      end
    end

    describe "#controller_for" do
      it "instantiates an object of the right controller class for this event" do
        router.controller_for(simple_event).should be_a_kind_of(Channels::MyChanController)
        router.controller_for(complex_event).should be_a_kind_of(Channels::OtherChanController)
      end
    end

    describe "#route!" do
      it "takes an event and route it to the right controller" do
        Channels::MyChanController.any_instance.should_receive(:initialize)
          .with(simple_event).and_call_original
        Channels::MyChanController.any_instance.should_receive(:default_action)
          .and_call_original
        Channels::MyChanController.any_instance.should_receive(:action)
          .and_call_original

        router.route! simple_event
      end

      it "routes to the default controller if no specific exists" do
        ChannelController.any_instance.should_receive(:default_action)

        router.route! simple_event2
      end

      it "#trigger_event on the right channel" do
        WebsocketRails['other_chan:foo'].should_receive(:trigger_event).with(complex_event)

        router.route! complex_event
      end

      it "#trigger_event on all the channels the controller routed the event to" do
        WebsocketRails[:my_chan].should_receive(:trigger_event).with(simple_event)
        WebsocketRails[:other_chan].should_receive(:trigger_event).with(simple_event)

        router.route! simple_event
      end

      it "doesn't trigger event if route was set to :none (nil)" do
        Channels::MyChanController.any_instance.should_receive(:default_action)
          .and_call_original
        Channel.any_instance.should_not_receive(:trigger_event)

        router.route! unrouted_event
      end

      it "doesn't trigger event if the event is unroutable (not a chan event)" do
        Channel.any_instance.should_not_receive(:trigger_event)

        router.route! unroutable_event
      end

      it "is accessible on ChannelRouter via delegation" do
        router.should_receive(:route!).with(unroutable_event)

        ChannelRouter.route! unroutable_event
      end
    end
  end
end
