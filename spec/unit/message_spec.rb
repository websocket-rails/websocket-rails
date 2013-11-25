require "spec_helper"

module WebsocketRails
  describe Message do

    let(:message) { 'raw message from socket' }
    let(:connection) { double(Connection) }

    describe ".deserialize" do
      it "needs to be implemented in a subclass" do
        expect { Message.deserialize(message, connection) }.
          to raise_exception(NotImplementedError)
      end
    end

    describe "#type" do
      it "needs to be implemented in a subclass" do
        expect { subject.type }.to raise_exception(NotImplementedError)
      end
    end

    describe "#protocol" do
      it "needs to be implemented in a subclass" do
        expect { subject.protocol }.to raise_exception(NotImplementedError)
      end
    end

    describe "#serialize" do
      it "needs to be implemented in a subclass" do
        expect { subject.serialize }.to raise_exception(NotImplementedError)
      end
    end

  end
end
