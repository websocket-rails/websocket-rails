require 'spec_helper'

module WebsocketRails
  
  class ConnectionAdapters::Test < ConnectionAdapters::Base
    def self.accepts?(env)
      true
    end
  end
  
  describe ConnectionAdapters do
    
    let(:env) { Rack::MockRequest.env_for('/websocket') }
    
    context ".register_adapter" do
      it "should store a reference to the adapter in the adapters array" do
        ConnectionAdapters.register_adapter( ConnectionAdapters::Test )
        ConnectionAdapters.adapters.include?( ConnectionAdapters::Test ).should be_true
      end
    end
    
    context ".establish_connection" do
      it "should return the correct connection adapter instance" do
        adapter = ConnectionAdapters.establish_connection( env )
        adapter.class.should == ConnectionAdapters::Test
      end      
    end
    
  end
    
  module ConnectionAdapters
    describe Base do
      
      let(:env) { Rack::MockRequest.env_for('/websocket') }
      
      subject { Base.new( env ) }
      
      context "new adapters" do
        it "should register themselves in the adapters array when inherited" do
          adapter = Class.new( ConnectionAdapters::Base )
          ConnectionAdapters.adapters.include?( adapter ).should be_true
        end
        
        Base::ADAPTER_EVENTS.each do |event|
          it "should define accessor methods for #{event}" do
            proc = lambda { |event| true }
            subject.__send__("#{event}=".to_sym,proc) 
            subject.__send__(event).should == true
          end
        end
      end
      
      context "#send" do
        it "should raise a NotImplementedError exception" do
          expect { subject.send :message }.to raise_exception( NotImplementedError )
        end
      end
      
    end
  end
end