require 'spec_helper'

module WebsocketRails
  module DataStore
    describe Base do
      it "extends Hash" do
        subject.should be_a Hash
      end

      it "allows indifferent access" do
        subject['key'] = true
        subject[:key].should == true
      end
    end

    describe Connection do
      before do
        @connection = double('connection')
        @connection.stub(:client_id).and_return(1)
      end

      let(:subject) { DataStore::Connection.new(@connection) }

      it "stores a reference to it's connection" do
        subject.connection.should == @connection
      end
    end

    describe Controller do
      before do
        @controller = double('controller')
      end

      let(:subject) { DataStore::Controller.new(@controller) }

      it "stores a reference to it's controller" do
        subject.controller.should == @controller
      end
    end
  end
end
