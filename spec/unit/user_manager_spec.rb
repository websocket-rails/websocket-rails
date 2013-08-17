require "spec_helper"

module WebsocketRails

  describe ".users" do
    it "returns the global instance of UserManager" do
      WebsocketRails.users.should be_a UserManager
    end

    context "when synchronization is enabled" do
      before do
        WebsocketRails.stub(:synchronize?).and_return(true)
      end

      context "and the user is not connected to this worker" do
        it "publishes the event to redis" do
          Synchronization.should_receive(:publish) do |event|
            event.user_id.should == :missing
          end

          WebsocketRails.users[:missing].send_message :test, :data
        end
      end
    end
  end

  describe UserManager do

    let(:connection) { double('Connection') }

    describe "#[]=" do
      it "store's a reference to a connection in the user's hash" do
        subject[:username] = connection
        subject.users[:username].should == connection
      end
    end

    describe "#[]" do
      before do
        subject[:username] = connection
      end

      context "when passed a known user identifier" do
        it "returns that user's connection" do
          subject[:username].should == connection
        end
      end
    end

    describe "#delete" do
      before do
        subject[:username] = connection
      end

      it "deletes the connection from the users hash" do
        subject.delete(:username)
        subject[:username].should be_a UserManager::MissingUser
      end
    end
  end
end
