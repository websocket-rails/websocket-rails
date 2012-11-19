require "spec_helper"
require "eventmachine"

module WebsocketRails
  describe Synchronization do

    around(:each) do |example|
      EM.run do
        Fiber.new do
          redis = Redis.new
          redis.del "websocket_rails.active_servers"
          example.run
        end.resume
        EM.stop
      end
    end

    let(:subject) { Synchronization }

    describe "#publish" do
      it "should add the serialized event to the websocket_rails.events channel" do
        event = Event.new(:test_event, :channel => 'synchrony', :data => 'hello channel')
        Redis.any_instance.should_receive(:publish).with("websocket_rails.events", event.serialize)

        subject.publish(event)
      end
    end

    describe "#generate_unique_token" do
      before do
        SecureRandom.stub(:urlsafe_base64).and_return(1, 5, 3)
      end

      after do
        subject.send(:generate_unique_token)
        @redis.del "websocket_rails.active_servers"
      end

      it "should generate a unique token" do
        raise 'FTW'
        SecureRandom.should_receive(:urlsafe_base64).at_least(1).times
      end

      it "should generate another id if the current id is already registered" do
        @redis.sadd "websocket_rails.active_servers", 1
        subject.send(:generate_unique_token)
        subject.server_token.should == 2
      end
    end

    describe "#register_server" do
      it "should add the unique token to the active_servers key in redis" do
        subject.register_server(1)

        @redis.sismember("websocket_rails.active_servers", 1).should be_true
        @redis.del "websocket_rails.active_servers"
      end
    end

  end
end
