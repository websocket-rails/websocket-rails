require 'spec_helper'
require 'support/mock_web_socket'

module WebsocketRails
  module ConnectionAdapters
    describe WebSocket do
      
      before do
        @socket = MockWebSocket.new
        Faye::WebSocket.stub(:new).and_return(@socket)
        @adapter = WebSocket.new( Hash.new )
      end
      
      WebSocket::ADAPTER_EVENTS.each do |event|
        it "should delegate ##{event} and ##{event}= to the Faye::WebSocket object" do
          @socket.should_receive(event)
          @socket.should_receive("#{event}=".to_sym)
        
          @adapter.__send__( "#{event}=".to_sym, Proc.new {|e| true } )
          @adapter.__send__( event )
        end
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
