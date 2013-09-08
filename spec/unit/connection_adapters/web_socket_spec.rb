require 'spec_helper'
require 'support/mock_web_socket'

module WebsocketRails
  module ConnectionAdapters
    describe WebSocket do

      before do
        @socket = MockWebSocket.new
        Faye::WebSocket.stub(:new).and_return(@socket)
        @adapter = WebSocket.new( mock_request, double('Dispatcher').as_null_object )
      end

      describe "#send" do
        it "should send the message to the websocket connection" do
          @socket.should_receive(:send).with(:message)
          @adapter.send :message
        end
      end

      describe "#close!" do
        it "calls #close on the underlying WebSocket connection" do
          @socket.should_receive(:close)
          @adapter.close!
        end
      end

    end
  end
end
