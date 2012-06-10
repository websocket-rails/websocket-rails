require 'spec_helper'

module WebsocketRails
  module ConnectionAdapters
    describe Http do
      
      let(:env) { Rack::MockRequest.env_for('/websocket') }
      
      subject { Http.new( env ) }
      
      it "should be a subclass of ConnectionAdapters::Base" do
        subject.class.superclass.should == ConnectionAdapters::Base
      end

      it "should set the Content-Length header to text/plain" do
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
    end
  end
end
