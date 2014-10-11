require 'spec_helper'
require "ostruct"

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
        expect(io.string).to include("info logged")
      end
    end

    describe "#debug" do
      it "logs the message" do
        object.debug "debug logged"
        expect(io.string).to include("debug logged")
      end
    end

    describe "log_exception" do
      let(:exception) { Exception.new('kaputt!').tap { |e| e.set_backtrace(['line 1', 'line 2']) } }

      it "logs the exception message" do
        object.log_exception(exception)
        expect(io.string).to include('kaputt!')
      end

      it "logs the backtrace" do
        object.log_exception(exception)
        expect(io.string).to include("line 1")
        expect(io.string).to include("line 2")
      end
    end

    context "logging an event" do
      before do
        options = {
          namespace: :logger,
          connection: double('connection')
        }
        @event = Event.new(:logged_event, {message: "hello"}, options)
      end

      describe "#log_event_start" do
        it "logs the event information" do
          object.log_event_start(@event)
          expect(io.string).to include("Started Event:")
          expect(io.string).to include("logger.logged_event")
        end
      end

      describe "#log_event_end" do
        it "logs the total time the event took to process" do
          time = 12
          object.log_event_end(@event, time)
          expect(io.string).to include("Event #{@event.encoded_name} Finished in #{time.to_f.to_d.to_s} seconds")
        end
      end

      describe "#log_event" do
        it "logs the start of the event" do
          expect(object).to receive(:log_event_start).with(@event)
          object.log_event(@event) { true }
        end

        it "logs the end of the event" do
          time = Time.now
          allow(Time).to receive(:now).and_return(time)
          expect(object).to receive(:log_event_end).with(@event, 0)
          object.log_event(@event) { true }
        end

        it "executes the block" do
          executed = false
          object.log_event(@event) { executed = true }
          expect(executed).to eq(true)
        end

        it "logs any exceptions" do
          exception = Exception.new("ouch")
          expect(object).to receive(:log_exception).with(exception)
          expect { object.log_event(@event) { raise exception } }.
            to raise_exception(exception)
        end
      end
    end

    describe "#log_data?" do
      before do
        @hash_event = Event.new(:log_test, {test: true})
        @string_event = Event.new(:log_test, "message")
        @object_event = Event.new(:log_test, OpenStruct.new)
      end

      it "returns true if data is an allowed type" do
        expect(object.log_data?(@hash_event)).to eq(true)
        expect(object.log_data?(@string_event)).to eq(true)
      end

      it "returns false if the data is not an allowed type" do
        expect(object.log_data?(@object_event)).to eq(false)
      end
    end

    describe "#log_event?" do
      context "with an internal event" do
        before do
          @event = Event.new(:internal, nil, :namespace => :websocket_rails)
        end

        context "when WebsocketRails.config.log_internal_events? is false" do
          it "returns false" do
            WebsocketRails.config.log_internal_events = false
            expect(object.log_event?(@event)).to eq(false)
          end
        end

        context "when WebsocketRails.config.log_internal_events? is true" do
          it "returns true" do
            WebsocketRails.config.log_internal_events = true
            expect(object.log_event?(@event)).to eq(true)
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
            expect(object.log_event?(@event)).to eq(true)
          end
        end

        context "when WebsocketRails.config.log_internal_events? is true" do
          it "returns true" do
            WebsocketRails.config.log_internal_events = true
            expect(object.log_event?(@event)).to eq(true)
          end
        end
      end
    end

  end
end
