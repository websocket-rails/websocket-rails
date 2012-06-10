require 'spec_helper'

module WebsocketRails
  describe ConnectionManager do
    include Rack::Test::Methods
   
    def app
      @app ||= ConnectionManager.new
    end

    def open_connection
      subject.call(env)
    end
    
    let(:connections) { subject.connections }
    let(:env) { Rack::MockRequest.env_for('/websocket') }
    
    before(:each) do
      @mock_socket = ConnectionAdapters::Base.new(env)
      ConnectionAdapters.stub(:establish_connection).and_return(@mock_socket)
      @dispatcher = double('dispatcher').as_null_object
      Dispatcher.stub(:new).and_return(@dispatcher)
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

    context "new POST event" do
      before(:each) do
        @mock_http = ConnectionAdapters::Http.new(env)
        app.connections << @mock_http
      end
      
      it "should receive the new event for the correct connection" do
        @dispatcher.should_receive(:receive).with('data',@mock_http)
        post '/websocket', {:client_id => @mock_http.id, :data => 'data'}
      end
    end
    
    context "open connections" do
      before(:each) do
        ConnectionAdapters.stub(:establish_connection).and_return(@mock_socket,ConnectionAdapters::Base.new(env))
        4.times { open_connection }
      end
      
      context "when receiving a new event" do
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
        ConnectionAdapters.stub(:establish_connection).and_return(false)
      end
      
      it "should return a 400 bad request error code" do
        open_connection.first.should == 400
      end
    end
  end
end
