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
      allow(connection).to receive(:id).and_return(1)
      allow(event).to receive(:connection).and_return(connection)
    end

    it "stores a reference to the dispatcher" do
      expect(subject.dispatcher).to eq(dispatcher)
    end

    it "maintains a hash of controller data stores" do
      expect(subject.controller_stores).to be_a Hash
    end

    describe "#new_for_event" do

      context "when Rails is defined and env is set to development" do

        it "creates and returns a controller instance of the InternalController" do
          rails_env = double(:rails_env)
          allow(Rails).to receive(:env).and_return rails_env
          allow(rails_env).to receive(:development?).and_return true
          controller = subject.new_for_event(event, InternalController, 'some_method')
          expect(controller.class).to eq(InternalController)
        end

      end

      it "creates and returns a new controller instance" do
        controller = subject.new_for_event(event, TestController, 'some_method')
        expect(controller.class).to eq(TestController)
      end

      it "initializes the controller with the correct data_store" do
        store = double('data_store')
        subject.controller_stores[TestController] = store
        controller = subject.new_for_event(event, TestController, 'some_method')
        expect(controller.controller_store).to eq(store)
      end

      it "initializes the controller with the correct event" do
        controller = subject.new_for_event(event, TestController, 'some_method')
        expect(controller.event).to eq(event)
      end

      it "initializes the controller with the correct dispatcher" do
        controller = subject.new_for_event(event, TestController, 'some_method')
        expect(controller._dispatcher).to eq(dispatcher)
      end

      it "calls #initialize_session on the controller only once" do
        expect_any_instance_of(TestController).to receive(:initialize_session).once
        3.times { subject.new_for_event(event, TestController, 'some_method') }
      end
    end

  end
end
