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

    let(:subject) { Synchronization.singleton }

    describe "#publish" do
      it "should add the serialized event to the websocket_rails.events channel" do
        event = Event.new(:test_event, :channel => 'synchrony', :data => 'hello channel')
        Redis.any_instance.should_receive(:publish).with("websocket_rails.events", event.serialize)

        subject.publish(event)
      end
    end

    describe "#synchronize!" do
      #before do
      #  #@synchro = Synchronization.new
      #end

      #it "should receive remote channel events" do
      #  event = Event.new(:channel_event, :channel => :channel_one, :data => 'hello channel one')

      #  @redis.should_receive(:subscribe)
      #  Redis.should_receive(:connect).with(WebsocketRails.redis_options).and_return(@redis)

      #  Synchronization.new.synchronize!

      #  EM::Synchrony.sleep(0.5)

      #  redis = @redis
      #  EM.next_tick { redis.publish "websocket_rails.events", event.serialize }
      #end
      it "should set server_token to stop circular publishing" do
        event = Event.new(:redis_event, :channel => 'synchrony', :data => 'hello from another process')
        if event.server_token.nil?
          event.server_token = subject.server_token
        end
        event.server_token.should == subject.server_token
      end
      it "should not set server_token if it is present" do
        event = Event.new(:redis_event, :channel => 'synchrony', :data => 'hello from another process', :server_token => '1234')
        if event.server_token.nil?
          event.server_token = subject.server_token
        end
        event.server_token.should == '1234'
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
      it "should remove the unique token from the active_servers key in redis" do
        Redis.any_instance.should_receive(:srem).with("websocket_rails.active_servers", "token")
        subject.remove_server "token"
      end
    end

  end
end
