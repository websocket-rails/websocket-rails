require 'spec_helper'

module WebsocketRails
  class ClassWithLogging
    include Logging
  end

#  describe ClassWithLogging do
#
#    describe "#log" do
#      context "when log_level = :warn" do
#        before do
#          WebsocketRails.setup do |config|
#            config.log_level = :warn
#          end
#        end
#
#        it "should not print to the console" do
#          subject.should_not_receive(:puts).with("test message")
#          subject.log "test message"
#        end
#      end
#
#      context "log_level = :debug" do
#        before do
#          WebsocketRails.setup do |config|
#            config.log_level = :debug
#          end
#        end
#
#        it "should print to the console if log_level is :debug" do
#          subject.should_receive(:puts).with("test message")
#          subject.log "test message"
#        end
#      end
#    end
#  end
end
