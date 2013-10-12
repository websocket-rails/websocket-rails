require 'spec_helper'

module WebsocketRails
  describe ChannelController do
    let(:router)         { ChannelRouter.instance }
    let(:simple_event)   { Event.new 'action', id: 42, channel: :mock_channel }
    let(:event_other)    { Event.new 'other', data: { test: 'blabla' }, channel: 'mock_channel:context1:context2' }
    let(:complex_event)  { Event.new 'chanevent2', id: 42, channel: 'other_chan:foo' }
    let(:complex_event2) { Event.new 'chanevent2', id: 42, channel: 'other_chan:foo:bar' }

    describe "#new" do
      it "creates a ChannelController when given an event" do
        ChannelController.new(event_other).should be_a_kind_of(ChannelController)
      end
    end

    describe "#context" do
      it "returns nil if event has no context" do
        controller = ChannelController.new(simple_event)
        controller.context.should be_nil
      end
      it "returns an array of [context, ...] when event has a context" do
        controller = ChannelController.new(complex_event)
        controller.context.should eq(['foo'])
        controller = ChannelController.new(complex_event2)
        controller.context.should eq(['foo', 'bar'])
      end
    end


  end
end
