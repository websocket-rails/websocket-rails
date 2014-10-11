require 'spec_helper'

module WebsocketRails
  describe Connection do
    let(:connection_manager) { double(ConnectionManager).as_null_object }
    let(:dispatcher) { double(Dispatcher).as_null_object }
    let(:channel_manager) { double(ChannelManager).as_null_object }
    let(:event) { double(Event).as_null_object }

    before do
      allow(connection_manager).to receive(:connections).and_return({})
      allow(dispatcher).to receive(:connection_manager).and_return(connection_manager)
      allow(Event).to receive(:deserialize).and_return(event)
    end

    subject { Connection.new(mock_request, dispatcher) }

    context "new connection" do
      it "should create a new DataStore::Connection instance" do
        expect(subject.data_store).to be_a DataStore::Connection
      end

      it "creates a unique ID" do
        allow(UUIDTools::UUID).to receive(:random_create).and_return(1024)
        expect(subject.id).to eq(1024)
      end

      it "opens a new Faye::WebSocket connection" do
        expect(subject.websocket).to be_a Faye::WebSocket
      end

      #before do
      #  WebsocketRails.config.stub(:user_identifier).and_return(:name)
      #  WebsocketRails::DelegationController.any_instance
      #    .stub_chain(:current_user, :name)
      #    .and_return('Frank')
      #  subject
      #end

      #it "adds itself to the UserManager Hash" do
      #  WebsocketRails.users['Frank'].should == subject
      #end
    end

    describe "#bind_messager_handler" do
      it "delegates websocket events to the appropriate message handler" do
        expect_any_instance_of(Faye::WebSocket).to receive(:onmessage=)
        expect_any_instance_of(Faye::WebSocket).to receive(:onclose=)
        expect_any_instance_of(Faye::WebSocket).to receive(:onerror=)
        subject
      end
    end

    describe "#send_message" do
      before do
        expect(subject).to receive(:trigger)
      end
      after do
        subject.send_message :message, "some_data"
      end

      it "sets it's user identifier on the event" do
        allow(subject).to receive(:user_identifier).and_return(:some_name_or_id)
        expect(Event).to receive(:new) { |name, options|
          expect(options[:user_id]).to eq(:some_name_or_id)
        }.and_call_original
      end

      it "sets the connection property of the event correctly" do
        allow(subject).to receive(:user_identifier).and_return(:some_name_or_id)
        expect(Event).to receive(:new) { |name, options|
          expect(options[:connection]).to eq(subject)
        }.and_call_original
      end
    end

    describe "#protocol" do
      it "delegates to the websocket object" do
        expect(subject.websocket).to receive(:protocol)
        subject.protocol
      end
    end

    describe "#send" do
      it "delegates to the websocket connection" do
        expect(subject.websocket).to receive(:send).with(:message)
        subject.send :message
      end
    end

    describe "#close!" do
      it "delegates to the websocket connection" do
        expect(subject.websocket).to receive(:close)
        subject.close!
      end
    end

    describe "#close_connection" do
      before do
        allow(subject).to receive(:user_identifier).and_return(1)
        @connection_manager = double('connection_manager').as_null_object
        allow(subject).to receive_message_chain(:dispatcher, :connection_manager).and_return(@connection_manager)
        allow(subject).to receive(:dispatch)
      end

      it "calls #close_connection on the conection manager" do
        expect(@connection_manager).to receive(:close_connection).with(subject)
        subject.close_connection
      end

      it "deletes it's data_store" do
        expect(subject.data_store).to receive(:destroy!)
        subject.close_connection
      end
    end

    describe "#user_connection?" do
      context "when a user is signed in" do
        before do
          allow(subject).to receive(:user_identifier).and_return("Jimbo Jones")
        end

        it "returns true" do
          expect(subject.user_connection?).to eq(true)
        end
      end

      context "when a user is signed out" do
        before do
          allow(subject).to receive(:user_identifier).and_return(nil)
        end

        it "returns true" do
          expect(subject.user_connection?).to eq(false)
        end
      end
    end

    describe "#user" do
      it "provides access to the current_user object" do
        user = double('User')
        allow(subject).to receive(:user_identifier).and_return true
        allow(subject).to receive_message_chain(:controller_delegate, :current_user).and_return user
        expect(subject.user).to eq(user)
      end
    end

    describe "#trigger" do
      it "passes a serialized event to the connections #send method" do
        allow(event).to receive(:serialize).and_return('test')
        expect(subject).to receive(:send).with "test"
        subject.trigger event
      end
    end
  end
end
