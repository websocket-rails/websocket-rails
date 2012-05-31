require 'spec_helper'
require 'support/mock_web_socket'

module WebsocketRails
  describe ConnectionManager do
    
    def open_connection
      subject.call(@env)
    end
    
    let(:connections) { subject.connections }
    
    before(:each) do
      Faye::WebSocket.stub(:websocket?).and_return(true)
      @mock_socket = MockWebSocket.new
      Faye::WebSocket.stub(:new).and_return(@mock_socket)
      @dispatcher = double('dispatcher').as_null_object
      Dispatcher.stub(:new).and_return(@dispatcher)
      @env = []     
    end
    
    context "new connections" do
      it "should add one to the total connection count" do
        expect { open_connection }.to change { connections.count }.by(1)
      end
      
      it "should execute the :client_connected event" do
        @dispatcher.should_receive(:dispatch) do |event,data,connection|
          event.should == 'client_connected'
          connection.should == @mock_socket
        end
        open_connection
      end
      
      it "should store the new connection in the @connections array" do
        open_connection
        connections.include?(@mock_socket).should be_true
      end
      
      it "should return an Async Rack response" do
        open_connection.should == [ -1, {}, [] ]
      end
    end
    
    context "new event on an open connection" do
      before(:all) { MockEvent = Struct.new(:data) }
      before(:each) { open_connection }      
      
      it "should dispatch the appropriate event through the Dispatcher" do
        mock_event = MockEvent.new(:new_message)
        @dispatcher.should_receive(:receive) do |event,connection|
          event.should == :new_message
          connection.should == @mock_socket
        end
        @mock_socket.onmessage(mock_event)
      end
    end
    
    context "open connections" do
      before(:each) do
        Faye::WebSocket.stub(:new).and_return(MockWebSocket.new,MockWebSocket.new,@mock_socket,MockWebSocket.new)
        4.times { open_connection }
      end
      
      context "when closing" do      
        it "should remove the connection object from the @connections array" do
          @mock_socket.onclose
          connections.include?(@mock_socket).should be_false
        end
      
        it "should decrement the connection count by one" do
          expect { @mock_socket.onclose }.to change { connections.count }.by(-1)
        end
      
        it "should dispatch the :client_disconnected event" do
          @dispatcher.should_receive(:dispatch) do |event,data,connection|
            event.should == 'client_disconnected'
            connection.should == @mock_socket
          end
          @mock_socket.onclose
        end
      end
    
      context "when experiencing errors" do        
        it "should dispatch the :client_error event" do
          @mock_socket.stub(:onclose)
          @dispatcher.should_receive(:dispatch) do |event,data,connection|
            event.should == 'client_error'
            connection.should == @mock_socket
          end
          @mock_socket.onerror
        end
        
        it "should execute the #onclose procedure on connection" do
          @mock_socket.should_receive(:onclose)
          @mock_socket.onerror
        end
      end
    end
    
    context "invalid connections" do
      before(:each) do
        Faye::WebSocket.stub(:websocket?).and_return(false)
      end
      
      it "should return a 400 bad request error code" do
        open_connection.first.should == 400
      end
    end
  end
end