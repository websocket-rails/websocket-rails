require 'spec_helper'

module WebsocketRails

  describe ".channel_manager" do
    it "should load a new channel manager when first called" do
      expect(WebsocketRails.channel_manager).to be_a ChannelManager
    end
  end

  describe ".[]" do
    it "should delegate to channel manager" do
      expect_any_instance_of(ChannelManager).to receive(:[]).with(:awesome_channel)
      WebsocketRails[:awesome_channel]
    end
  end

  describe ".channel_tokens" do
    it "should delegate to channel manager" do
      expect_any_instance_of(ChannelManager).to receive(:channel_tokens)
      WebsocketRails.channel_tokens
    end
  end

  describe ChannelManager do

    describe "#channel_tokens" do
      it "should return a Hash-like" do
        subject.channel_tokens.respond_to? :[]
        subject.channel_tokens.respond_to? :has_key?
      end

      it 'is used to store Channel\'s token' do
        expect_any_instance_of(ChannelManager).to receive(:channel_tokens)
          .at_least(:twice).and_call_original
        token = Channel.new(:my_new_test_channel).token
        expect(WebsocketRails.channel_tokens[:my_new_test_channel]).to eq(token)
      end
    end

    describe "#[]" do
      context "accessing a channel" do
        it "should create the channel if it does not exist" do
          expect(subject[:awesome_channel].class).to eq(Channel)
        end
      end
    end

    describe "unsubscribe" do
      it "should unsubscribe connection from all channels" do
        expect(subject[:awesome_channel]).to receive(:unsubscribe).with(:some_connection)
        #subject[:awesome_channel]
        subject.unsubscribe(:some_connection)
      end
    end

  end
end
