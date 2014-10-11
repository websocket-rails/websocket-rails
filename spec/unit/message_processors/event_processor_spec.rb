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
          allow(event).to receive(:type).and_return :websocket_rails
        end

        it "returns true for :websocket_rails events" do
          expect(subject.processes?(event)).to be true
        end
      end

      context "processing an inbound event" do
        before do
          allow_any_instance_of(EventMap).to receive(:routes_for).with(any_args).and_yield(EventTarget, :test_method)
          allow(event).to receive(:name).and_return(:test_method)
          allow(event).to receive(:encoded_name).and_return(:test_method)
          allow(event).to receive(:data).and_return(:some_message)
          allow(event).to receive(:connection).and_return(connection)
          allow(event).to receive(:is_channel?).and_return(false)
          allow(event).to receive(:is_user?).and_return(false)
          allow(event).to receive(:is_invalid?).and_return(false)
          allow(event).to receive(:is_internal?).and_return(false)
          allow(event).to receive(:type).and_return(:websocket_rails)
        end

        it "should execute the correct method on the target class" do
          expect_any_instance_of(EventTarget).to receive(:process_action).with(:test_method, event)
          subject.process_message(event)
        end

        context "channel events" do
          it "should forward the data to the correct channel" do
            event = Event.new('test', 'data', :channel => :awesome_channel)
            channel = double('channel')
            expect(channel).to receive(:trigger_event).with(event)
            expect(WebsocketRails).to receive(:[]).with(:awesome_channel).and_return(channel)
            subject.process_message event
          end

          context "when filtering channel events" do
            before do
              allow(subject).to receive(:filtered_channels).and_return({:awesome_channel => EventTarget})
            end

            it "should execute the method on the correct target class" do
              event = Event.new('test_method', {:data => 'some data'},{ :channel => :awesome_channel})
              expect_any_instance_of(EventTarget).to receive(:process_action).with(:test_method, event)
              subject.process_message event
            end
          end

          context "filtered channel catch all events" do
            before do
              allow(subject).to receive(:filtered_channels).and_return({:awesome_channel => [EventTarget, :catch_all_method]})
            end

            it "should execute the correct method(s) on the target class" do
              event = Event.new('test_method', {:data => 'some data'},{ :channel => :awesome_channel})
              expect_any_instance_of(EventTarget).to receive(:process_action).with(:test_method, event)
              expect_any_instance_of(EventTarget).to receive(:process_action).with(:catch_all_method, event)
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
              expect(subject.process_message(@event)).to eq(nil)
            end
          end

          context "and the user is connected to this server" do
            before do
              @connection = double('Connection')
              WebsocketRails.users["username"] = @connection
            end

            it "triggers the event on the correct user" do
              expect(WebsocketRails.users["username"]).to receive(:trigger).with @event
              subject.process_message @event
            end
          end
        end

        context "invalid events" do
          before do
            allow(event).to receive(:is_invalid?).and_return(true)
          end

          it "should not dispatch the event" do
            expect(subject).not_to receive(:route)
            subject.process_message(event)
          end
        end
      end

      context 'record_invalid_defined?' do

        it 'should return false when RecordInvalid is not defined' do
          if Object.const_defined?('ActiveRecord')
            swizzle_module_const(ActiveRecord, 'RecordInvalid','TempRecordInvalid') do
              expect(subject.send(:record_invalid_defined?)).to be false
            end
          else
            set_temp_module_const(Object, 'ActiveRecord', Module.new) do
              expect(subject.send(:record_invalid_defined?)).to be false
            end
          end
        end

        it 'should return false when ActiveRecord is not defined' do
          swizzle_module_const(Object, 'ActiveRecord', 'TempActiveRecord') do
            expect(subject.send(:record_invalid_defined?)).to be false
          end
        end

        it 'should return true if ActiveRecord::RecordInvalid is defined' do
          if Object.const_defined?('ActiveRecord')
            if ActiveRecord.const_defined?('RecordInvalid')
              expect(subject.send(:record_invalid_defined?)).to be true
            else
              set_temp_module_const(ActiveRecord, 'RecordInvalid', Class.new) do
                expect(subject.send(:record_invalid_defined?)).to be true
              end
            end
          else
            set_temp_module_const(Object, 'ActiveRecord', Module.new) do
              set_temp_module_const(ActiveRecord, 'RecordInvalid', Class.new) do
                expect(subject.send(:record_invalid_defined?)).to be true
              end
            end
          end

        end

        context 'when ActiveRecord::RecordInvalid is not defined' do

          it 'should check that exception can be converted to JSON' do
            expect(subject).to receive(:record_invalid_defined?).and_return false
            ex = double(:exception)
            expect(ex).to receive(:respond_to?).with(:to_json).and_return true
            exception_data = subject.send(:extract_exception_data, ex)
            expect(exception_data).to eq(ex)
          end

        end
      end

    end
  end
end
