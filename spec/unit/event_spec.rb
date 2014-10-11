require 'spec_helper'

module WebsocketRails
  describe Event do
    let(:encoded_message) { '["new_message",{"message":"this is a message"},{"id":"1234"}]' }
    let(:encoded_message_string) { '["new_message","this is a message",{"id":"1234"}]' }
    let(:namespace_encoded_message_string) { '["product.new_message","this is a message",{"id":"1234"}]' }
    let(:namespace_encoded_message) { '["product.new_message",{"message":"this is a message"},{"id":"1234"}]' }
    let(:channel_encoded_message_string) { '["new_message","this is a message",{"id":"1234","channel":"awesome_channel","user_id":null,"success":null,"result":null,"token":null,"server_token":"1234"}]' }
    let(:synchronizable_encoded_message) { '["new_message",{"message":"this is a message"},{"id":"1234","server_token":"1234"}]' }
    let(:connection) { double('connection') }
    let(:wrongly_encoded_message) { '["new_message",[{"id":"1234","data":{"message":"this is a message"}}]}]' }

    before { allow(connection).to receive(:id).and_return(1) }

    describe ".deserialize" do
      context "messages in the global namespace" do
        it "should decode a new message and store it" do
          event = Event.deserialize(encoded_message, connection)
          expect(event.connection).to eq(connection)
          expect(event.name).to eq(:new_message)
          expect(event.namespace).to eq([:global])
          expect(event.data[:message]).to eq('this is a message')
        end
      end

      context "messages in a child namespace" do
        it "should store the event with the correct namesapce" do
          event = Event.deserialize(namespace_encoded_message, connection)
          expect(event.namespace).to eq([:global,:product])
          expect(event.name).to eq(:new_message)
          expect(event.data[:message]).to eq('this is a message')
        end
      end

      context "invalid messages" do
        it "should return an invalid event if data is wrongly encoded" do
          event = Event.deserialize( wrongly_encoded_message, connection )
          expect(event.is_invalid?).to be true
        end
      end
    end

    describe ".new_on_open" do
      before { @event = Event.new_on_open connection, {:message => 'connected'} }

      it "should create an event named :client_connected" do
        expect(@event.name).to eq(:client_connected)
      end

      it "should send the connection id to the client" do
        expect(@event.data[:connection_id]).to eq("1")
      end

      it "should merge the optional data with the connection id" do
        expect(@event.data[:message]).to eq('connected')
      end
    end

    describe ".new_on_close" do
      it "should create an event named :client_disconnected" do
        event = Event.new_on_close(connection, "optional_data")
        expect(event.name).to eq(:client_disconnected)
        expect(event.data).to eq("optional_data")
        expect(event.connection).to eq(connection)
      end
    end

    describe ".new_on_error" do
      it "should create an event named :client_error" do
        event = Event.new_on_error(connection, "optional_data")
        expect(event.name).to eq(:client_error)
        expect(event.data).to eq("optional_data")
        expect(event.connection).to eq(connection)
      end
    end

    context "new namespaced events" do
      it "should store the namespace in the namespace attribute" do
        event = Event.new "event", {}, :connection => connection, :namespace => :product
        expect(event.namespace).to eq([:global,:product])
        expect(event.name).to eq(:event)
      end

      it "should store nested namespaces in the namespace attribute" do
        event = Event.new "event", {}, :connection => connection, :namespace => [:product,:x_ray_vision]
        expect(event.namespace).to eq([:global,:product,:x_ray_vision])
        expect(event.name).to eq(:event)
      end
    end

    context "new channel events" do
      it "should store the channel name in the channel attribute" do
        event = Event.new "event", {}, :connection => connection, :channel => :awesome_channel
        expect(event.channel).to eq(:awesome_channel)
        expect(event.name).to eq(:event)
      end

      it "should not raise an error if the channel name cannot be symbolized" do
        expect { Event.new "event", {}, :connection => connection, :channel => 5 }.to_not raise_error
        event = Event.new "event", {}, :connection => connection, :channel => 5
        expect(event.channel).to eq(:"5")
      end
    end

    describe "#is_channel?" do
      it "should return true if an event belongs to a channel" do
        event = Event.new "event", "data", :channel => :awesome_channel
        expect(event.is_channel?).to be true
      end
    end

    describe "#is_user?" do
      it "returns true if the event is meant for a specific user" do
        event = Event.new "event", "data", :user_id => :username
        event.is_user?
      end
    end

    describe "#is_invalid?" do
      it "returns true if the event name is :invalid_event" do
        event = Event.new(:invalid_event)
        expect(event.is_invalid?).to be true
      end
    end

    describe "#is_internal?" do
      it "returns true if the event is namespaced under websocket_rails" do
        event = Event.new(:internal_event, nil, :namespace => :websocket_rails)
        expect(event.is_internal?).to be true
      end
    end

    describe "#serialize" do
      context "messages in the global namespace" do
        it "should not add the global namespace to the event name" do
          event = Event.deserialize encoded_message_string, connection
          raw_data = event.serialize
          data = JSON.parse raw_data
          expect(data[0]).to eq("new_message")
        end
      end

      context "messages in a child namespace" do
        it "should add the namespace to the front of the event name" do
          event = Event.deserialize namespace_encoded_message_string, connection
          raw_data = event.serialize
          data = JSON.parse raw_data
          expect(data[0]).to eq("product.new_message")
        end
      end

      context "messages for a channel" do
        it "should add the channel name as the first element of the serialized array" do
          event = Event.deserialize channel_encoded_message_string, connection
          expect(event.serialize).to eq(channel_encoded_message_string)
        end
      end

      context "messages for synchronization" do
        it "should include the unique server token" do
          event = Event.deserialize synchronizable_encoded_message, connection
          raw_data = event.serialize
          data = JSON.parse(raw_data)
          expect(data[2]['server_token']).to eq('1234')
        end
      end

      describe "#as_json" do
        it "returns a Hash representation of the Event" do
          options = {channel: :awesome_channel}
          event = Event.new('test', {'test' => 'test'}, options)
          expect(event.as_json[0]).to eq(:test)
          expect(event.as_json[1]).to eq({'test' => 'test'})
          expect(event.as_json[2][:channel]).to eq(options[:channel])
        end
      end
    end

  end
end
