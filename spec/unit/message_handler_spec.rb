require "spec_helper"

module WebsocketRails
  describe MessageHandler do

    describe "#accepts?" do
      it "returns true when no protocol has been negotiated" do
        MessageHandler.accepts?('').should be true
      end
    end

    let(:connection_manager) { double(ConnectionManager).as_null_object }
    let(:dispatcher) { double(Dispatcher).as_null_object }
    let(:connection) { double(Connection).as_null_object }
    let(:channel_manager) { double(ChannelManager).as_null_object }
    let(:event) { double(Event).as_null_object }

    before do
      connection_manager.stub(:connections).and_return({})
      dispatcher.stub(:connection_manager).and_return(connection_manager)
      connection.stub(:dispatcher).and_return(dispatcher)
      Event.stub(:deserialize).and_return(event)
    end

    subject { MessageHandler.new(connection) }

    describe "#on_open" do
      it "should dispatch an on_open event" do
        on_open_event = double('event').as_null_object
        subject.stub(:send)
        Event.should_receive(:new_on_open).and_return(on_open_event)
        dispatcher.should_receive(:dispatch).with(on_open_event)
        subject.on_open
      end
    end

    describe "#on_message" do
      it "should forward the data to the dispatcher" do
        dispatcher.should_receive(:dispatch).with(event)
        subject.on_message encoded_message
      end
    end

    describe "#on_close" do
      it "should dispatch an on_close event" do
        on_close_event = double('event')
        Event.should_receive(:new_on_close).and_return(on_close_event)
        dispatcher.should_receive(:dispatch).with(on_close_event)
        subject.on_close("data")
      end
    end

    describe "#on_error" do
      it "should dispatch an on_error event" do
        subject.stub(:on_close)
        on_error_event = double('event').as_null_object
        Event.should_receive(:new_on_error).and_return(on_error_event)
        dispatcher.should_receive(:dispatch).with(on_error_event)
        subject.on_error("data")
      end

      it "should fire the on_close event" do
        data = "test_data"
        subject.should_receive(:on_close).with(data)
        subject.on_error("test_data")
      end
    end

  end
end
