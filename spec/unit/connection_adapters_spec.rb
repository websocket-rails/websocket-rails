require 'spec_helper'

module WebsocketRails
  
  class ConnectionAdapters::Test < ConnectionAdapters::Base
    def self.accepts?(env)
      true
    end
  end
  
  describe ConnectionAdapters do
    
    context ".register" do
      it "should store a reference to the adapter in the adapters array" do
        ConnectionAdapters.register( ConnectionAdapters::Test )
        ConnectionAdapters.adapters.include?( ConnectionAdapters::Test ).should be_true
      end
    end
    
    context ".establish_connection" do
      it "should return the correct connection adapter instance" do
        adapter = ConnectionAdapters.establish_connection( env, double('Dispatcher').as_null_object )
        adapter.class.should == ConnectionAdapters::Test
      end
    end
    
  end
    
  module ConnectionAdapters
    describe Base do
      let(:dispatcher) { double('Dispatcher').as_null_object }
      let(:channel_manager) { double('ChannelManager').as_null_object }
      let(:event) { double('Event').as_null_object }
      before  { Event.stub(:new_from_json).and_return(event) }
      subject { Base.new( env, dispatcher ) }
      
      context "new adapters" do
        it "should register themselves in the adapters array when inherited" do
          adapter = Class.new( ConnectionAdapters::Base )
          ConnectionAdapters.adapters.include?( adapter ).should be_true
        end
      end

      describe "#on_open" do
        it "should dispatch an on_open event" do
          on_open_event = double('event').as_null_object
          subject.stub(:send)
          Event.should_receive(:new_on_open).and_return(on_open_event)
          dispatcher.should_receive(:dispatch).with(on_open_event)
          subject.on_open
        end
      end

      describe "#on_message" do
        it "should forward the data to the dispatcher" do
          dispatcher.should_receive(:dispatch).with(event)
          subject.on_message encoded_message
        end
      end

      describe "#on_close" do
        it "should dispatch an on_close event" do
          on_close_event = double('event')
          Event.should_receive(:new_on_close).and_return(on_close_event)
          dispatcher.should_receive(:dispatch).with(on_close_event)
          subject.on_close("data")
        end
      end

      describe "#on_error" do
        it "should dispatch an on_error event" do
          subject.stub(:on_close)
          on_error_event = double('event').as_null_object
          Event.should_receive(:new_on_error).and_return(on_error_event)
          dispatcher.should_receive(:dispatch).with(on_error_event)
          subject.on_error("data")
        end

        it "should fire the on_close event" do
          data = "test_data"
          subject.should_receive(:on_close).with(data)
          subject.on_error("test_data")
        end
      end
      
      describe "#send" do
        it "should raise a NotImplementedError exception" do
          expect { subject.send :message }.to raise_exception( NotImplementedError )
        end
      end
      
      describe "#enqueue" do
        it "should add the event to the queue" do
          subject.enqueue 'event'
          subject.queue.queue.should == ['event']
        end
      end

      describe "#trigger" do
        it "should add the event to the queue" do
          subject.stub(:flush)
          subject.should_receive(:enqueue).with('event')
          subject.trigger 'event'
        end

        it "should flush the queue" do
          subject.should_receive(:flush)
          subject.trigger 'event'
        end
      end
    end
  end
end
