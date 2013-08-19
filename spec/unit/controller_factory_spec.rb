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

      context "when Rails is defined and env is set to development" do

        it "creates and returns a controller instance of the InternalController" do
          rails_env = double(:rails_env)
          Rails.stub(:env).and_return rails_env
          rails_env.stub(:development?).and_return true
          controller = subject.new_for_event(event, InternalController, 'some_method')
          controller.class.should == InternalController
        end

      end

      it "creates and returns a new controller instance" do
        controller = subject.new_for_event(event, TestController, 'some_method')
        controller.class.should == TestController
      end

      it "initializes the controller with the correct data_store" do
        store = double('data_store')
        subject.controller_stores[TestController] = store
        controller = subject.new_for_event(event, TestController, 'some_method')
        controller.controller_store.should == store
      end

      it "initializes the controller with the correct event" do
        controller = subject.new_for_event(event, TestController, 'some_method')
        controller.event.should == event
      end

      it "initializes the controller with the correct dispatcher" do
        controller = subject.new_for_event(event, TestController, 'some_method')
        controller._dispatcher.should == dispatcher
      end

      it "calls #initialize_session on the controller only once" do
        TestController.any_instance.should_receive(:initialize_session).once
        3.times { subject.new_for_event(event, TestController, 'some_method') }
      end
    end

  end
end
