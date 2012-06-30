require 'spec_helper'

module WebsocketRails

  describe ".channel_manager" do
    it "should load a new channel manager when first called" do
      WebsocketRails.channel_manager.should be_a ChannelManager
    end
  end

  describe ".[]" do
    it "should delegate to channel manager" do
      ChannelManager.any_instance.should_receive(:[]).with(:awesome_channel)
      WebsocketRails[:awesome_channel]
    end
  end

  describe ChannelManager do

    describe "#[]" do
      context "accessing a channel" do
        it "should create the channel if it does not exist" do
          subject[:awesome_channel].class.should == Channel
        end
      end
    end

  end
end
