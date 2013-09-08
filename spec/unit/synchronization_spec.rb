require "spec_helper"
require "eventmachine"
require "ostruct"

module WebsocketRails
  describe Synchronization do

    around(:each) do |example|
      EM.run do
        Fiber.new do
          @redis = Redis.new(WebsocketRails.config.redis_options)
          @redis.del "websocket_rails.active_servers"
          example.run
        end.resume
      end
    end

    after(:each) do
      @redis.del "websocket_rails.active_servers"
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
      # need to add an integration test to cover this.
    end

    describe "#trigger_incoming" do
      context "when dispatching channel events" do
        before do
          @event = Event.new(:channel_event, :channel => :channel_one, :data => 'hello channel one')
        end

        it "triggers the event on the correct channel" do
          WebsocketRails[:channel_one].should_receive(:trigger_event).with @event
          subject.trigger_incoming @event
        end
      end

      context "when dispatching user events" do
        before do
          @event = Event.new(:channel_event, :user_id => "username", :data => 'hello channel one')
        end

        context "and the user is not connected to this server" do
          it "does nothing" do
            subject.trigger_incoming(@event).should == nil
          end
        end

        context "and the user is connected to this server" do
          before do
            @connection = double('Connection')
            WebsocketRails.users["username"] = @connection
          end

          it "triggers the event on the correct user" do
            WebsocketRails.users["username"].should_receive(:trigger).with @event
            subject.trigger_incoming @event
          end
        end
      end
    end

    describe "#generate_server_token" do
      before do
        SecureRandom.stub(:urlsafe_base64).and_return(1, 2, 3)
      end

      after do
        @redis.del "websocket_rails.active_servers"
      end

      it "should generate a unique server token" do
        SecureRandom.should_receive(:urlsafe_base64).at_least(1).times
        subject.generate_server_token
      end

      it "should generate another id if the current id is already registered" do
        @redis.sadd "websocket_rails.active_servers", 1
        token = subject.generate_server_token
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

    describe "#register_user" do
      before do
        @connection = double('Connection')
        @user = User.new
        @user.attributes.update(name: 'Frank The Tank', email: 'frank@tank.com')
        @user.instance_variable_set(:@new_record, false)
        @user.instance_variable_set(:@destroyed, false)
        @connection.stub(:user_identifier).and_return 'Frank The Tank'
        @connection.stub(:user).and_return @user
      end

      it "stores the serialized user object in redis" do
        @user.persisted?.should == true
        Redis.any_instance.should_receive(:hset).with("websocket_rails.users", @connection.user_identifier, @user.as_json.to_json)
        Synchronization.register_user(@connection)
      end
    end

    describe "#destroy_user" do
      it "stores the serialized user object in redis" do
        Redis.any_instance.should_receive(:hdel).with("websocket_rails.users", 'user_id')
        Synchronization.destroy_user('user_id')
      end
    end

    describe "#find_user" do
      it "retrieves the serialized user object in redis" do
        Redis.any_instance.should_receive(:hget).with("websocket_rails.users", 'test')
        Synchronization.find_user('test')
      end
    end

    describe "#all_users" do
      it "retrieves the entire serialized users hash redis" do
        Redis.any_instance.should_receive(:hgetall).with("websocket_rails.users")
        Synchronization.all_users
      end
    end

  end
end
