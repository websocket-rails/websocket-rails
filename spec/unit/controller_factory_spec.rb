require "spec_helper"

module WebsocketRails
  describe ControllerFactory do

    class TestController < BaseController
      attr_reader :_dispatcher, :_event
      def initialize_session
        true
      end
    end

    let(:dispatcher) { double('dispatcher') }
    let(:connection) { double('connection') }
    let(:event) { double('event') }

    subject { ControllerFactory.new(dispatcher) }

    before do
      connection.stub(:id).and_return(1)
      event.stub(:connection).and_return(connection)
    end

    it "stores a reference to the dispatcher" do
      subject.dispatcher.should == dispatcher
    end

    it "maintains a hash of controller data stores" do
      subject.controller_stores.should be_a Hash
    end

    describe "#new_for_event" do
      it "creates and returns a new controller instance" do
        controller = subject.new_for_event(event, TestController)
        controller.class.should == TestController
      end

      it "initializes the controller with the correct data_store" do
        store = double('data_store')
        subject.controller_stores[TestController] = store
        controller = subject.new_for_event(event, TestController)
        controller.controller_store.should == store
      end

      it "initializes the controller with the correct event" do
        controller = subject.new_for_event(event, TestController)
        controller.event.should == event
      end

      it "initializes the controller with the correct dispatcher" do
        controller = subject.new_for_event(event, TestController)
        controller._dispatcher.should == dispatcher
      end

    end

  end
end
