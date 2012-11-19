require "spec_helper"
require "eventmachine"

module WebsocketRails
  describe Synchronization do

    around(:each) do |example|
      EM.run do
        Fiber.new do
          @redis = Redis.new
          @redis.del "websocket_rails.active_servers"
          example.run
        end.resume
      end
    end

    after(:each) do
      EM.stop
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
        SecureRandom.stub(:urlsafe_base64).and_return(1, 2, 3)
      end

      after do
        @redis.del "websocket_rails.active_servers"
      end

      it "should generate a unique token" do
        SecureRandom.should_receive(:urlsafe_base64).at_least(1).times
        subject.generate_unique_token
      end

      it "should generate another id if the current id is already registered" do
        @redis.sadd "websocket_rails.active_servers", 1
        token = subject.generate_unique_token
        token.should == 2
      end
    end

    describe "#register_server" do
      it "should add the unique token to the active_servers key in redis" do
        Redis.any_instance.should_receive(:sadd).with("websocket_rails.active_servers", "token")
        subject.register_server "token"
      end
    end

    describe "#remove_server" do
      it "should add the unique token to the active_servers key in redis" do
        Redis.any_instance.should_receive(:srem).with("websocket_rails.active_servers", "token")
        subject.remove_server "token"
      end
    end

  end
end
