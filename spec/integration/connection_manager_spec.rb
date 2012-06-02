require 'spec_helper'
require 'support/mock_web_socket'

module WebsocketRails
  describe ConnectionManager do
    
    def define_test_events
      WebsocketRails.route_block = nil
      WebsocketRails::Events.describe_events do
        subscribe :client_connected, to: ChatController, with_method: :new_user
        subscribe :change_username, to: ChatController, with_method: :change_username
        subscribe :client_error, to: ChatController, with_method: :error_occurred
        subscribe :client_disconnected, to: ChatController, with_method: :delete_user
      end
    end
    
    before(:all) { define_test_events }
    
    let(:env) { Hash.new }
    let(:socket) { MockWebSocket.new }
    
    before(:each) do
      Faye::WebSocket.stub(:websocket?).and_return(true)
      Faye::WebSocket.stub(:new).and_return(socket)
      @server = ConnectionManager.new
    end
    
    context "new connections" do
      it "should execute the controller action associated with the 'client_connected' event" do
        ChatController.any_instance.should_receive(:new_user)
        @server.call( env )
      end
    end
    
    context "active connections" do
      context "new message from client" do
        let(:test_message) { ['change_username',{user_name: 'Joe User'}] }
        let(:encoded_message) { test_message.to_json }
      
        before(:each) { MockEvent = Struct.new(:data) }
      
        it "should execute the controller action associated with the received event" do
          mock_event = MockEvent.new( encoded_message )
          ChatController.any_instance.should_receive(:change_username)
          @server.call( env )
          socket.onmessage( mock_event )
        end
      end
    
      context "client error" do
        it "should execute the controller action associated with the 'client_error' event" do
          ChatController.any_instance.should_receive(:error_occurred)
          @server.call( env )
          socket.onerror
        end
      end
      
      context "client disconnects" do
        it "should execute the controller action associated with the 'client_disconnected' event" do
          ChatController.any_instance.should_receive(:delete_user)
          @server.call( env )
          socket.onclose
        end
      end
    end
    
  end
end