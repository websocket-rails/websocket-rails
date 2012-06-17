require 'spec_helper'
require 'support/mock_web_socket'

module WebsocketRails
  module ConnectionAdapters
    describe WebSocket do
      
      before do
        @socket = MockWebSocket.new
        Faye::WebSocket.stub(:new).and_return(@socket)
        @adapter = WebSocket.new( env, double('Dispatcher').as_null_object )
      end
      
      context "#send" do
        it "should send the message to the websocket connection" do
          @socket.should_receive(:send).with(:message)
          @adapter.send :message
        end
      end
      
    end
  end
end
