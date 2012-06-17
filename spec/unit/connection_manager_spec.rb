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
    let(:dispatcher) { subject.dispatcher }
    
    before(:each) do
      ConnectionAdapters::Base.any_instance.stub(:send)
      @mock_socket = ConnectionAdapters::Base.new(env,dispatcher)
      ConnectionAdapters.stub(:establish_connection).and_return(@mock_socket)
    end
    
    context "new connections" do
      it "should add one to the total connection count" do
        expect { open_connection }.to change { connections.count }.by(1)
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
        @mock_http = ConnectionAdapters::Http.new(env,dispatcher)
        app.connections << @mock_http
      end
      
      it "should receive the new event for the correct connection" do
        @mock_http.should_receive(:on_message).with(encoded_message)
        post '/websocket', {:client_id => @mock_http.id, :data => encoded_message}
      end
    end
    
    context "open connections" do
      before(:each) do
        ConnectionAdapters.stub(:establish_connection).and_return(@mock_socket,ConnectionAdapters::Base.new(env,dispatcher))
        4.times { open_connection }
      end
      
      context "when receiving a new event" do
        before(:each) { open_connection }

        it "should dispatch the appropriate event through the Dispatcher" do
          mock_event = [234234,"new_message","data"].to_json
          dispatcher.should_receive(:dispatch) do |event|
            event.name.should == :new_message
            event.data.should == "data"
            event.connection.should == @mock_socket
          end
          @mock_socket.on_message(mock_event)
        end
      end
      
      context "when closing" do
        it "should remove the connection object from the @connections array" do
          @mock_socket.on_close
          connections.include?(@mock_socket).should be_false
        end
      
        it "should decrement the connection count by one" do
          expect { @mock_socket.on_close }.to change { connections.count }.by(-1)
        end
      
        it "should dispatch the :client_disconnected event" do
          dispatcher.should_receive(:dispatch) do |event|
            event.name.should == :client_disconnected
            event.connection.should == @mock_socket
          end
          @mock_socket.on_close
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
