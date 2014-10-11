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
      allow(Connection).to receive(:websocket?).and_return(true)
      allow_any_instance_of(Connection).to receive(:send)
      @mock_socket = Connection.new(mock_request, dispatcher)
      allow(Connection).to receive(:new).and_return(@mock_socket)
    end

    describe ".connection_manager" do
      it "returns the global connection manager" do
        expect(WebsocketRails.connection_manager).to be_a ConnectionManager
      end
    end

    describe "#initialize" do
      it "should create an empty connections hash" do
        expect(subject.connections).to be_a Hash
      end

      it "should create a new dispatcher instance" do
        expect(subject.dispatcher).to be_a Dispatcher
      end
    end

    context "new connections" do
      it "should add one to the total connection count" do
        expect { open_connection }.to change { connections.count }.by(1)
      end

      it "should store the new connection in the @connections Hash" do
        open_connection
        expect(connections[@mock_socket.id.to_s]).to eq(@mock_socket)
      end

      it "should return an Async Rack response" do
        expect(open_connection).to eq([ -1, {}, [] ])
      end

      context "user connections" do
        before do
          allow(@mock_socket).to receive(:user_connection?).and_return true
          allow(@mock_socket).to receive(:user_identifier).and_return "El Jefe"
          open_connection
        end

        it "stores the connection in the UserManager" do
          expect(WebsocketRails.users["El Jefe"].connections.first).to eq(@mock_socket)
        end
      end
    end

    context "open connections" do
      before(:each) do
        allow(Connection).to receive(:new).and_return(@mock_socket, Connection.new(mock_request, dispatcher))
        4.times { open_connection }
      end

      context "when closing" do
        it "should remove the connection object from the @connections hash" do
          @mock_socket.on_close
          expect(connections.has_key?(@mock_socket.id.to_s)).to be false
        end

        it "should decrement the connection count by one" do
          expect { @mock_socket.on_close }.to change { connections.count }.by(-1)
        end

        it "should dispatch the :client_disconnected event" do
          expect(dispatcher).to receive(:dispatch) do |event|
            expect(event.name).to eq(:client_disconnected)
            expect(event.connection).to eq(@mock_socket)
          end
          @mock_socket.on_close
        end

        context "user connections" do
          before do
            allow(@mock_socket).to receive(:user_connection?).and_return true
            allow(@mock_socket).to receive(:user_identifier).and_return "El Jefe"
          end

          it "deletes the connection from the UserManager" do
            @mock_socket.on_close
            expect(WebsocketRails.users["El Jefe"].class).to eq(UserManager::MissingConnection)
          end
        end
      end

    end

    context "invalid connections" do
      before(:each) do
        allow(Connection).to receive(:new).and_raise(InvalidConnectionError)
      end

      it "should return a 400 bad request error code" do
        expect(open_connection.first).to eq(400)
      end
    end
  end
end
