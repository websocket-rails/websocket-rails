require 'spec_helper'

module WebsocketRails

  describe SpecHelperEvent do

    before do
      @dispatcher = double(:dispatcher)
      Dispatcher.stub(:new).and_return @dispatcher
      @event = SpecHelperEvent.new('my_event', data: 'my_data')
    end

    describe 'initialize' do

      it 'should initialize the name and namespace of the event' do
        @event.namespace.should == [:global]
        @event.name.should == :my_event
      end

      it 'should initialize the data of the event' do
        @event.data.should == 'my_data'
      end

      it 'should set the event to not triggered' do
        @event.should_not be_triggered
      end

    end

    describe 'trigger' do

      it 'should set the triggered variable to true' do
        @event.trigger
        @event.should be_triggered
      end

    end

    describe 'dispatch' do

      it 'should invoke dispatch on the dispatcher object' do
        @dispatcher.should_receive(:dispatch).with(@event)
        @event.dispatch
      end

      it 'should return itself to be able to chain matchers' do
        @dispatcher.stub(:dispatch)
        @event.dispatch.should == @event
      end

    end

  end

end

describe 'create_event' do

  it 'should create a SpecHelperEvent with the correct parameters' do
    event = create_event('my_event','my_data')
    event.should be_a WebsocketRails::SpecHelperEvent
    event.name.should == :my_event
    event.data.should == 'my_data'
  end

end