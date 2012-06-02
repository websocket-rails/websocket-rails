require 'spec_helper'

module WebsocketRails
  describe ConnectionManager do
    
    def define_test_events
      WebsocketRails.route_block = nil
      WebsocketRails::Events.describe_events do
        subscribe :client_connected, to: ChatController, with_method: :new_user
        subscribe :change_username, to: ChatController, with_method: :change_username
      end
    end
    
    before(:all) { define_test_events }
    
    let(:env) { Hash.new }
    let(:socket) { MockWebSocket.new }
    
    before(:each) do
      Faye::WebSocket.stub(:new).and_return(MockWebSocket.new)
      @server = ConnectionManager.new
    end
    
    context "new connections" do
      it "should execute the controller action associated with the 'client_connected' event" do
        ChatController.any_instance.should_receive(:new_user)
        define_test_events
        @server.call( env )
        #ChatController.new.send(:new_user)
      end
      
      it "should have a ChatController present" do
        ChatController.new.should be_present
      end
    end
    
  end
end