require 'spec_helper'
require 'support/mock_web_socket'

module WebsocketRails
  describe ConnectionManager, "integration test", :type => :request do

    class ProductController < BaseController
      def update_list; true; end
    end

    def define_test_events
      WebsocketRails.config.route_block = nil
      WebsocketRails::EventMap.describe do
        subscribe :client_connected, :to => ChatController, :with_method => :new_user
        subscribe :change_username, :to => ChatController, :with_method => :change_username
        subscribe :client_error, :to => ChatController, :with_method => :error_occurred
        subscribe :client_disconnected, :to => ChatController, :with_method => :delete_user

        subscribe :update_list, :to => ChatController, :with_method => :update_user_list

        namespace :products do
          subscribe :update_list, :to => ProductController, :with_method => :update_list
        end
      end
    end

    before do
      define_test_events
      MessageProcessors::Registry.processors = [MessageProcessors::EventProcessor]
    end

    shared_examples "an evented rack server" do
      context "new connections" do
        it "should execute the controller action associated with the 'client_connected' event" do
          expect_any_instance_of(ChatController).to receive(:new_user)
          @server.call( env )
          socket.on_open
          sleep(0.1)
        end
      end

      context "active connections" do
        context "new message from client" do
          let(:test_message) { ['change_username',{:user_name => 'Joe User'}] }
          let(:encoded_message) { test_message.to_json }

          it "should execute the controller action associated with the received event" do
            expect_any_instance_of(ChatController).to receive(:change_username)
            @server.call( env )
            socket.on_message( encoded_message )
            sleep(0.1)
          end
        end

        context "new message from client under a namespace" do
          let(:test_message) { ['products.update_list',{:product => 'x-ray-vision'}] }
          let(:encoded_message) { test_message.to_json }

          it "should execute the controller action under the correct namespace" do
            expect_any_instance_of(ChatController).to_not receive(:update_user_list)
            expect_any_instance_of(ProductController).to receive(:update_list)
            @server.call( env )
            socket.on_message( encoded_message )
            sleep(0.1)
          end
        end

        context "subscribing to a channel" do
          let(:channel_message) { ['websocket_rails.subscribe',{:channel => 'test_chan'}] }
          let(:encoded_channel_message) { channel_message.to_json }

          it "should subscribe the connection to the correct channel" do
            channel = WebsocketRails[:test_chan]
            @server.call( env )
            socket.on_message( encoded_channel_message )
            expect(channel).to receive(:subscribe).with(socket)
            sleep(0.1)
          end
        end

        context "client error" do
          it "should execute the controller action associated with the 'client_error' event" do
            expect_any_instance_of(ChatController).to_not receive(:error_occurred)
            @server.call( env )
            socket.on_error
            sleep(0.1)
          end
        end

        context "client disconnects" do
          it "should execute the controller action associated with the 'client_disconnected' event" do
            expect_any_instance_of(ChatController).to_not receive(:delete_user)
            @server.call( env )
            socket.on_close
            sleep(0.1)
          end

          it "should unsubscribe from channels" do
            channel = WebsocketRails[:test_chan]
            @server.call( env )
            expect(channel).to receive(:unsubscribe).with(socket)
            socket.on_close
          end
        end
      end
    end

    context "WebSocket Adapter" do
      let(:socket) { @server.connections["uuid"] }

      before do
        allow(UUIDTools::UUID).to receive(:random_create).and_return "uuid"
        allow(Connection).to receive(:websocket?).and_return true
        allow(Faye::WebSocket).to receive(:new).and_return(MockWebSocket.new)
        @server = ConnectionManager.new
      end

      it_behaves_like 'an evented rack server'
    end

  end
end
