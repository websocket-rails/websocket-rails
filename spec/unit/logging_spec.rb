require 'spec_helper'

module WebsocketRails
  describe Logging do

    class LoggedClass
      include Logging
    end

    let(:io) { StringIO.new }
    let(:object) { LoggedClass.new }

    before do
      WebsocketRails.config.logger = Logger.new(io)
    end

    describe "#info" do
      it "logs the message" do
        object.info "info logged"
        io.string.should include("info logged")
      end
    end

    describe "#debug" do
      it "logs the message" do
        object.debug "debug logged"
        io.string.should include("debug logged")
      end
    end

    describe "log_exception" do
      let(:exception) { Exception.new('kaputt!').tap { |e| e.set_backtrace(['line 1', 'line 2']) } }

      it "logs the exception message" do
        object.log_exception(exception)
        io.string.should include('kaputt!')
      end

      it "logs the backtrace" do
        object.log_exception(exception)
        io.string.should include("line 1")
        io.string.should include("line 2")
      end
    end

    context "logging an event" do
      before do
        data = {
          namespace: :logger,
          data: {message: "hello"},
          connection: double('connection')
        }
        @event = Event.new(:logged_event, data)
      end

      describe "#log_event_start" do
        it "logs the event information" do
          object.log_event_start(@event)
          io.string.should include("Started Event:")
          io.string.should include("logger.logged_event")
        end
      end

      describe "#log_event_end" do
        it "logs the total time the event took to process" do
          time = 12
          object.log_event_end(@event, time)
          io.string.should include("Event #{@event.encoded_name} Finished in #{time.to_f.to_d.to_s} seconds")
        end
      end

      describe "#log_event" do
        it "logs the start of the event" do
          object.should_receive(:log_event_start).with(@event)
          object.log_event(@event) { true }
        end

        it "logs the end of the event" do
          Time.stub(:now).and_return(1)
          object.should_receive(:log_event_end).with(@event, 0)
          object.log_event(@event) { true }
        end

        it "executes the block" do
          executed = false
          object.log_event(@event) { executed = true }
          executed.should == true
        end

        it "logs any exceptions" do
          exception = Exception.new("ouch")
          object.should_receive(:log_exception).with(exception)
          expect {
            object.log_event(@event) { raise exception }
          }.to raise_exception(exception)
        end
      end
    end

    describe "#log_event?" do
      context "with an internal event" do
        before do
          @event = Event.new(:internal, :namespace => :websocket_rails)
        end

        context "when WebsocketRails.config.log_internal_events? is false" do
          it "returns false" do
            WebsocketRails.config.log_internal_events = false
            object.log_event?(@event).should == false
          end
        end

        context "when WebsocketRails.config.log_internal_events? is true" do
          it "returns true" do
            WebsocketRails.config.log_internal_events = true
            object.log_event?(@event).should == true
          end
        end
      end

      context "with an external event" do
        before do
          @event = Event.new(:external)
        end

        context "when WebsocketRails.config.log_internal_events? is false" do
          it "returns true" do
            WebsocketRails.config.log_internal_events = false
            object.log_event?(@event).should == true
          end
        end

        context "when WebsocketRails.config.log_internal_events? is true" do
          it "returns true" do
            WebsocketRails.config.log_internal_events = true
            object.log_event?(@event).should == true
          end
        end
      end
    end

  end
end
