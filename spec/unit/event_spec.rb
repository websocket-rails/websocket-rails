require 'spec_helper'

module WebsocketRails
  describe Event do
    let(:encoded_message) { '["new_message",{"message":"this is a message"}]' }
    let(:connection) { double('connection') }

    describe ".new_from_json" do
      it "should decode a new message and store it" do
        event = Event.new_from_json( encoded_message, connection )
        event.connection.should == connection
        event.name.should == :new_message
        event.data[:message].should == 'this is a message'
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
  end
end
