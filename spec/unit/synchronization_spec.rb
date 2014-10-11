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

    let(:subject) { Synchronization.sync }

    describe "#publish_remote" do
      it "should add the serialized event to the websocket_rails.events channel" do
        event = Event.new(:test_event, 'hello channel', :channel => 'synchrony')
        expect_any_instance_of(Redis).to receive(:publish).with("websocket_rails.events", event.serialize)

        subject.publish_remote(event)
      end
    end

    describe "#synchronize!" do
      # need to add an integration test to cover this.
    end

    describe "#process_inbound" do
      context "when dispatching channel events" do
        before do
          @event = Event.new(:channel_event, 'hello channel one', :channel => :channel_one)
        end

        it "triggers the event on the correct channel" do
          expect(WebsocketRails[:channel_one]).to receive(:trigger_event).with @event
          subject.process_inbound @event
        end
      end
    end

    describe "#generate_server_token" do
      before do
        allow(SecureRandom).to receive(:urlsafe_base64).and_return(1, 2, 3)
      end

      after do
        @redis.del "websocket_rails.active_servers"
      end

      it "should generate a unique server token" do
        expect(SecureRandom).to receive(:urlsafe_base64).at_least(1).times
        subject.generate_server_token
      end

      it "should generate another id if the current id is already registered" do
        @redis.sadd "websocket_rails.active_servers", 1
        token = subject.generate_server_token
        expect(token).to eq(2)
      end
    end

    describe "#register_server" do
      it "should add the unique token to the active_servers key in redis" do
        expect_any_instance_of(Redis).to receive(:sadd).with("websocket_rails.active_servers", "token")
        subject.register_server "token"
      end
    end

    describe "#remove_server" do
      it "should remove the unique token from the active_servers key in redis" do
        expect_any_instance_of(Redis).to receive(:srem).with("websocket_rails.active_servers", "token")
        subject.remove_server "token"
      end
    end

    describe "#register_remote_user" do
      before do
        @connection = double('Connection')
        @user = User.new
        @user.attributes.update(name: 'Frank The Tank', email: 'frank@tank.com')
        @user.instance_variable_set(:@new_record, false)
        @user.instance_variable_set(:@destroyed, false)
        allow(@connection).to receive(:user_identifier).and_return 'Frank The Tank'
        allow(@connection).to receive(:user).and_return @user
      end

      it "stores the serialized user object in redis" do
        expect(@user.persisted?).to eq(true)
        expect_any_instance_of(Redis).to receive(:hset).with("websocket_rails.users", @connection.user_identifier, @user.as_json.to_json)
        subject.register_remote_user(@connection)
      end
    end

    describe "#destroy_remote_user" do
      it "stores the serialized user object in redis" do
        expect_any_instance_of(Redis).to receive(:hdel).with("websocket_rails.users", 'user_id')
        subject.destroy_remote_user('user_id')
      end
    end

    describe "#find_user" do
      it "retrieves the serialized user object in redis" do
        expect_any_instance_of(Redis).to receive(:hget).with("websocket_rails.users", 'test')
        subject.find_remote_user('test')
      end
    end

    describe "#all_users" do
      it "retrieves the entire serialized users hash redis" do
        expect_any_instance_of(Redis).to receive(:hgetall).with("websocket_rails.users")
        subject.all_remote_users
      end
    end

  end
end
