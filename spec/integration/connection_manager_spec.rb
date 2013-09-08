require 'spec_helper'
require 'support/mock_web_socket'

module WebsocketRails
  describe ConnectionManager, "integration test" do

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

    before(:all) do
      define_test_events
      if defined?(ConnectionAdapters::Test)
        ConnectionAdapters.adapters.delete( ConnectionAdapters::Test )
      end
    end

    around do |example|
      EM.run do
        example.run
      end
    end

    after do
      EM.stop
    end

    shared_examples "an evented rack server" do
      context "new connections" do
        it "should execute the controller action associated with the 'client_connected' event" do
          ChatController.any_instance.should_receive(:new_user)
          @server.call( env )
        end
      end

      context "active connections" do
        context "new message from client" do
          let(:test_message) { ['change_username',{:user_name => 'Joe User'}] }
          let(:encoded_message) { test_message.to_json }

          it "should execute the controller action associated with the received event" do
            ChatController.any_instance.should_receive(:change_username)
            @server.call( env )
            socket.on_message( encoded_message )
          end
        end

        context "new message from client under a namespace" do
          let(:test_message) { ['products.update_list',{:product => 'x-ray-vision'}] }
          let(:encoded_message) { test_message.to_json }

          it "should execute the controller action under the correct namespace" do
            ChatController.any_instance.should_not_receive(:update_user_list)
            ProductController.any_instance.should_receive(:update_list)
            @server.call( env )
            socket.on_message( encoded_message )
          end
        end

        context "subscribing to a channel" do
          let(:channel_message) { ['websocket_rails.subscribe',{:data => {:channel => 'test_chan'}}] }
          let(:encoded_channel_message) { channel_message.to_json }

          it "should subscribe the connection to the correct channel" do
            channel = WebsocketRails[:test_chan]
            @server.call( env )
            channel.should_receive(:subscribe).with(socket)
            socket.on_message encoded_channel_message
          end
        end

        context "client error" do
          it "should execute the controller action associated with the 'client_error' event" do
            ChatController.any_instance.should_receive(:error_occurred)
            @server.call( env )
            socket.on_error
          end
        end

        context "client disconnects" do
          it "should execute the controller action associated with the 'client_disconnected' event" do
            ChatController.any_instance.should_receive(:delete_user)
            @server.call( env )
            socket.on_close
          end

          it "should unsubscribe from channels" do
            channel = WebsocketRails[:test_chan]
            @server.call( env )
            channel.should_receive(:unsubscribe).with(socket)
            socket.on_close
          end
        end
      end
    end

    context "WebSocket Adapter" do
      let(:socket) { @server.connections.first[1] }

      before do
        ::Faye::WebSocket.stub(:websocket?).and_return(true)
        @server = ConnectionManager.new
      end

      it_behaves_like 'an evented rack server'
    end

    describe "HTTP Adapter" do
      let(:socket) { @server.connections.first[1] }

      before do
        @server = ConnectionManager.new
      end

      it_behaves_like 'an evented rack server'
    end

  end
end
