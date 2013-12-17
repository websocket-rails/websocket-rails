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
      Connection.stub(:websocket?).and_return(true)
      Connection.any_instance.stub(:send)
      @mock_socket = Connection.new(mock_request, dispatcher)
      Connection.stub(:new).and_return(@mock_socket)
    end

    describe ".connection_manager" do
      it "returns the global connection manager" do
        WebsocketRails.connection_manager.should be_a ConnectionManager
      end
    end

    describe "#initialize" do
      it "should create an empty connections hash" do
        subject.connections.should be_a Hash
      end

      it "should create a new dispatcher instance" do
        subject.dispatcher.should be_a Dispatcher
      end
    end

    context "new connections" do
      it "should add one to the total connection count" do
        expect { open_connection }.to change { connections.count }.by(1)
      end

      it "should store the new connection in the @connections Hash" do
        open_connection
        connections[@mock_socket.id.to_s].should == @mock_socket
      end

      it "should return an Async Rack response" do
        open_connection.should == [ -1, {}, [] ]
      end

      context "user connections" do
        before do
          @mock_socket.stub(:user_connection?).and_return true
          @mock_socket.stub(:user_identifier).and_return "El Jefe"
          open_connection
        end

        it "stores the connection in the UserManager" do
          WebsocketRails.users["El Jefe"].connections.first.should == @mock_socket
        end
      end
    end

    context "open connections" do
      before(:each) do
        Connection.stub(:new).and_return(@mock_socket, Connection.new(mock_request, dispatcher))
        4.times { open_connection }
      end

      context "when closing" do
        it "should remove the connection object from the @connections hash" do
          @mock_socket.on_close
          connections.has_key?(@mock_socket.id.to_s).should be_false
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

        context "user connections" do
          before do
            @mock_socket.stub(:user_connection?).and_return true
            @mock_socket.stub(:user_identifier).and_return "El Jefe"
          end

          it "deletes the connection from the UserManager" do
            @mock_socket.on_close
            WebsocketRails.users["El Jefe"].class.should == UserManager::MissingConnection
          end
        end
      end

    end

    context "invalid connections" do
      before(:each) do
        Connection.stub(:new).and_raise(InvalidConnectionError)
      end

      it "should return a 400 bad request error code" do
        open_connection.first.should == 400
      end
    end
  end
end
