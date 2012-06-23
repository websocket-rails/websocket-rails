require 'spec_helper'

module WebsocketRails
  describe Channel do
    subject { Channel.new :awesome_channel }
    it "should exist" do
      subject.should_not be_nil
    end
  end
end
