require "spec_helper"

module WebsocketRails
  describe AbstractMessageHandler do

    class TestHandler < AbstractMessageHandler
      def self.accepts?(protocol)
        protocol == "default"
      end
    end

    describe ".register_handler" do
      it "stores a reference to the handler in the handlers array" do
        expect(AbstractMessageHandler.handlers.include?(TestHandler)).to eq(true)
      end
    end

    describe ".handler_for_protocol" do
      it "returns the correct message handler class" do
        handler = AbstractMessageHandler.handler_for_protocol("default")
        expect(handler).to eq(TestHandler)
      end
    end

    let(:connection) { double(Connection) }

    describe "#initialize" do
      it "stores a reference to the connection" do
        handler = TestHandler.new(connection)
        expect(handler.connection).to eq(connection)
      end
    end

  end
end
