require 'spec_helper'

module WebsocketRails
  module ConnectionAdapters
    describe Http do
      
      subject { Http.new( env, double('Dispatcher').as_null_object ) }
      
      it "should be a subclass of ConnectionAdapters::Base" do
        subject.class.superclass.should == ConnectionAdapters::Base
      end

      it "should set the Content-Length header to text/json" do
        subject.headers['Content-Type'].should == "text/json"
      end

      it "should set the Transfer-Encoding header to chunked" do
        subject.headers['Transfer-Encoding'].should == "chunked"
      end

      context "#encode_chunk" do
        it "should properly encode strings" do
          subject.__send__(:encode_chunk,"test").should == "4\r\ntest\r\n"
        end
      end
      
      context "adapter methods" do
        before do
          @body = double('DeferrableBody').as_null_object
          Http::DeferrableBody.stub(:new).and_return(@body)
        end

        context "#define_deferrable_callbacks" do
          it "should define a callback for :succeeded" do
            @body.should_receive(:callback)
            subject
          end

          it "should define a callback for :failed" do
            @body.should_receive(:errback)
            subject
          end
        end

        context "#send" do
          it "should encode the message before sending" do
            subject.should_receive(:encode_chunk).with('test message')
            subject.send 'test message'
          end

          it "should enqueue the message on DeferrableBody" do
            encoded_message = subject.__send__(:encode_chunk,'test message')
            @body.should_receive(:chunk).with(encoded_message)
            subject.send 'test message'
          end
        end
      end
    end
  end
end
