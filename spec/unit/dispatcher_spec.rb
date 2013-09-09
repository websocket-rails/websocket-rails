require 'spec_helper'
require 'support/mock_web_socket'

def rename_module_const(mod, old_name, new_name)
  if mod.const_defined? old_name
    mod.const_set(new_name, mod.const_get(old_name))
    mod.send(:remove_const, old_name)
  end
end

def swizzle_module_const(mod, name, temp_name, &block)
  rename_module_const(mod, name, temp_name)
  yield block
  rename_module_const(mod, temp_name, name)
end

def set_temp_module_const(mod, name, value, &block)
  mod.const_set(name, value)
  yield block
  mod.send(:remove_const, name)
end

module WebsocketRails

  class EventTarget
    attr_reader :_event, :_dispatcher, :test_method
  end

  describe Dispatcher do

    let(:event) { double('Event').as_null_object }
    let(:connection) { MockWebSocket.new }
    let(:connection_manager) { double('connection_manager').as_null_object }
    subject { Dispatcher.new(connection_manager) }

    describe "#receive_encoded" do
      context "receiving a new message" do
        before do
          Event.stub(:new_from_json).and_return( event )
        end

        it "should be decoded from JSON and dispatched" do
          subject.stub(:dispatch) do |dispatch_event|
            dispatch_event.should == event
          end
          subject.receive_encoded(encoded_message,connection)
        end
      end
    end

    describe "#receive" do
      before { Event.stub(:new).and_return( event ) }

      it "should dispatch a new event" do
        subject.stub(:dispatch) do |dispatch_event|
          dispatch_event.should == event
        end
        subject.receive(:test_event,{},connection)
      end
    end

    context "dispatching an event" do
      before do
        EventMap.any_instance.stub(:routes_for).with(any_args).and_yield(EventTarget, :test_method)
        event.stub(:name).and_return(:test_method)
        event.stub(:data).and_return(:some_message)
        event.stub(:connection).and_return(connection)
        event.stub(:is_channel?).and_return(false)
        event.stub(:is_invalid?).and_return(false)
        event.stub(:is_internal?).and_return(false)
      end

      it "should execute the correct method on the target class" do
        EventTarget.any_instance.should_receive(:process_action).with(:test_method, event)
        subject.dispatch(event)
      end

      context "channel events" do
        it "should forward the data to the correct channel" do
          event = Event.new 'test', :data => 'data', :channel => :awesome_channel
          channel = double('channel')
          channel.should_receive(:trigger_event).with(event)
          WebsocketRails.should_receive(:[]).with(:awesome_channel).and_return(channel)
          subject.dispatch event
        end
      end

      context "invalid events" do
        before do
          event.stub(:is_invalid?).and_return(true)
        end

        it "should not dispatch the event" do
          subject.should_not_receive(:route)
          subject.dispatch(event)
        end
      end
    end

    describe "#send_message" do
      before do
        @event = Event.new_from_json( encoded_message, connection )
      end

      it "should send a message to the event's connection object" do
        connection.should_receive(:trigger).with(@event)
        subject.send_message @event
      end
    end

    describe "#broadcast_message" do
      before do
        connection_manager.stub(:connections).and_return({"connection_id" => connection})
        @event = Event.new_from_json( encoded_message, connection )
      end

      it "should send a message to all connected clients" do
        connection.should_receive(:trigger).with(@event)
        subject.broadcast_message @event
      end
    end

    describe 'record_invalid_defined?' do

      it 'should return false when RecordInvalid is not defined' do
        if Object.const_defined?('ActiveRecord')
          swizzle_module_const(ActiveRecord, 'RecordInvalid','TempRecordInvalid') do
            subject.send(:record_invalid_defined?).should be_false
          end
        else
          set_temp_module_const(Object, 'ActiveRecord', Module.new) do
            subject.send(:record_invalid_defined?).should be_false
          end
        end
      end

      it 'should return false when ActiveRecord is not defined' do
        swizzle_module_const(Object, 'ActiveRecord', 'TempActiveRecord') do
          subject.send(:record_invalid_defined?).should be_false
        end
      end

      it 'should return true if ActiveRecord::RecordInvalid is defined' do
        if Object.const_defined?('ActiveRecord')
          if ActiveRecord.const_defined?('RecordInvalid')
            subject.send(:record_invalid_defined?).should be_true
          else
            set_temp_module_const(ActiveRecord, 'RecordInvalid', Class.new) do
              subject.send(:record_invalid_defined?).should be_true
            end
          end
        else
          set_temp_module_const(Object, 'ActiveRecord', Module.new) do
            set_temp_module_const(ActiveRecord, 'RecordInvalid', Class.new) do
              subject.send(:record_invalid_defined?).should be_true
            end
          end
        end

      end

      context 'when ActiveRecord::RecordInvalid is not defined' do

        it 'should check that exception can be converted to JSON' do
          subject.should_receive(:record_invalid_defined?).and_return false
          ex = double(:exception)
          ex.should_receive(:respond_to?).with(:to_json).and_return true
          exception_data = subject.send(:extract_exception_data, ex)
          exception_data.should == ex
        end

      end

    end
  end
end
