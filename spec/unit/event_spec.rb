require 'spec_helper'

module WebsocketRails
  describe Event do
    let(:encoded_message) { '["new_message",{"message":"this is a message"}]' }
    let(:encoded_message_string) { '["new_message","this is a message"]' }
    let(:namespace_encoded_message_string) { '["product.new_message","this is a message"]' }
    let(:namespace_encoded_message) { '["product.new_message",{"message":"this is a message"}]' }
    let(:connection) { double('connection') }

    before { connection.stub!(:id).and_return(1) }

    describe ".new_from_json" do
      context "messages in the global namespace" do
        it "should decode a new message and store it" do
          event = Event.new_from_json( encoded_message, connection )
          event.connection.should == connection
          event.name.should == :new_message
          event.namespace.should == [:global]
          event.data[:message].should == 'this is a message'
        end
      end

      context "messages in a child namespace" do
        it "should store the event with the correct namesapce" do
          event = Event.new_from_json( namespace_encoded_message, connection )
          event.namespace.should == [:global,:product]
          event.name.should == :new_message
          event.data[:message].should == 'this is a message'
        end
      end
    end

    describe ".new_on_open" do
      before { @event = Event.new_on_open connection, {message: 'connected'} }

      it "should create an event named :client_connected" do
        @event.name.should == :client_connected
      end

      it "should send the connection id to the client" do
        @event.data[:connection_id].should == 1
      end

      it "should merge the optional data with the connection id" do
        @event.data[:message].should == 'connected'
      end
    end

    describe ".new_on_close" do
      it "should create an event named :client_disconnected" do
        event = Event.new_on_close( connection, "optional_data" )
        event.name.should == :client_disconnected
        event.data.should == "optional_data"
        event.connection.should == connection
      end
    end

    describe ".new_on_error" do
      it "should create an event named :client_error" do
        event = Event.new_on_error( connection, "optional_data" )
        event.name.should == :client_error
        event.data.should == "optional_data"
        event.connection.should == connection
      end
    end

    context "new namespaced events" do
      it "should store the namespace in the namespace attribute" do
        event = Event.new "event", {}, :connection => connection, :namespace => :product
        event.namespace.should == [:global,:product]
        event.name.should == :event
      end

      it "should store nested namespaces in the namespace attribute" do
        event = Event.new "event", {}, :connection => connection, :namespace => [:product,:x_ray_vision]
        event.namespace.should == [:global,:product,:x_ray_vision]
        event.name.should == :event
      end
    end

    describe "#serialize" do
      context "messages in the global namespace" do
        it "should not add the global namespace to the event name" do
          event = Event.new_from_json encoded_message_string, connection
          event.serialize.should == encoded_message_string
        end
      end

      context "messages in a child namespace" do
        it "should add the namespace to the front of the event name" do
          event = Event.new_from_json namespace_encoded_message_string, connection
          event.serialize.should == namespace_encoded_message_string
        end
      end
    end

  end
end
