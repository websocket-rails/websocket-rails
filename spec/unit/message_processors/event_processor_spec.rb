require "spec_helper"

def rename_module_const(mod, old_name, new_name)
  if mod.const_defined? old_name
    mod.const_set(new_name, mod.const_get(old_name).dup)
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
  module MessageProcessors

    class EventTarget
      attr_reader :_event, :_dispatcher, :test_method
    end

    describe EventProcessor do

      let(:connection_manager) { double(ConnectionManager) }
      let(:dispatcher) { Dispatcher.new(connection_manager) }
      let(:connection) { MockWebSocket.new }
      let(:event) { double(Event) }

      before do
        subject.dispatcher = dispatcher
      end

      describe "#processes?" do
        before do
          event.stub(:type).and_return :websocket_rails
        end

        it "returns true for :websocket_rails events" do
          subject.processes?(event).should be true
        end
      end

      context "processing an inbound event" do
        before do
          EventMap.any_instance.stub(:routes_for).with(any_args).and_yield(EventTarget, :test_method)
          event.stub(:name).and_return(:test_method)
          event.stub(:encoded_name).and_return(:test_method)
          event.stub(:data).and_return(:some_message)
          event.stub(:connection).and_return(connection)
          event.stub(:is_channel?).and_return(false)
          event.stub(:is_user?).and_return(false)
          event.stub(:is_invalid?).and_return(false)
          event.stub(:is_internal?).and_return(false)
          event.stub(:type).and_return(:websocket_rails)
        end

        it "should execute the correct method on the target class" do
          EventTarget.any_instance.should_receive(:process_action).with(:test_method, event)
          subject.process_message(event)
        end

        context "channel events" do
          it "should forward the data to the correct channel" do
            event = Event.new('test', 'data', :channel => :awesome_channel)
            channel = double('channel')
            channel.should_receive(:trigger_event).with(event)
            WebsocketRails.should_receive(:[]).with(:awesome_channel).and_return(channel)
            subject.process_message event
          end

          context "when filtering channel events" do
            before do
              subject.stub(:filtered_channels).and_return({:awesome_channel => EventTarget})
            end

            it "should execute the method on the correct target class" do
              event = Event.new('test_method', {:data => 'some data'},{ :channel => :awesome_channel})
              EventTarget.any_instance.should_receive(:process_action).with(:test_method, event)
              subject.process_message event
            end
          end

          context "filtered channel catch all events" do
            before do
              subject.stub(:filtered_channels).and_return({:awesome_channel => [EventTarget, :catch_all_method]})
            end

            it "should execute the correct method(s) on the target class" do
              event = Event.new('test_method', {:data => 'some data'},{ :channel => :awesome_channel})
              EventTarget.any_instance.should_receive(:process_action).with(:test_method, event)
              EventTarget.any_instance.should_receive(:process_action).with(:catch_all_method, event)
              subject.process_message event
            end
          end
        end

        context "when dispatching user events" do
          before do
            @event = Event.new(:channel_event, 'hello user', :user_id => "username")
          end

          context "and the user is not connected to this server" do
            it "does nothing" do
              subject.process_message(@event).should == nil
            end
          end

          context "and the user is connected to this server" do
            before do
              @connection = double('Connection')
              WebsocketRails.users["username"] = @connection
            end

            it "triggers the event on the correct user" do
              WebsocketRails.users["username"].should_receive(:trigger).with @event
              subject.process_message @event
            end
          end
        end

        context "invalid events" do
          before do
            event.stub(:is_invalid?).and_return(true)
          end

          it "should not dispatch the event" do
            subject.should_not_receive(:route)
            subject.process_message(event)
          end
        end
      end

      context 'record_invalid_defined?' do

        it 'should return false when RecordInvalid is not defined' do
          if Object.const_defined?('ActiveRecord')
            swizzle_module_const(ActiveRecord, 'RecordInvalid','TempRecordInvalid') do
              subject.send(:record_invalid_defined?).should be false
            end
          else
            set_temp_module_const(Object, 'ActiveRecord', Module.new) do
              subject.send(:record_invalid_defined?).should be false
            end
          end
        end

        it 'should return false when ActiveRecord is not defined' do
          swizzle_module_const(Object, 'ActiveRecord', 'TempActiveRecord') do
            subject.send(:record_invalid_defined?).should be false
          end
        end

        it 'should return true if ActiveRecord::RecordInvalid is defined' do
          if Object.const_defined?('ActiveRecord')
            if ActiveRecord.const_defined?('RecordInvalid')
              subject.send(:record_invalid_defined?).should be true
            else
              set_temp_module_const(ActiveRecord, 'RecordInvalid', Class.new) do
                subject.send(:record_invalid_defined?).should be true
              end
            end
          else
            set_temp_module_const(Object, 'ActiveRecord', Module.new) do
              set_temp_module_const(ActiveRecord, 'RecordInvalid', Class.new) do
                subject.send(:record_invalid_defined?).should be true
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
end
