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

      describe "#instances" do
        before do
          Base.clear_all_instances
          @connection = double('connection')
          @controller = double('controller')
        end

        it "keeps track of all instantiated instances" do
          store_one = Base.new
          store_two = Base.new

          store_one.instances.count.should == 2
          store_two.instances.count.should == 2
        end

        it "separates instances based on class name" do
          2.times { Connection.new(@connection) }
          4.times { Controller.new(@controller) }

          Connection.new(@connection).instances.count.should == 3
          Controller.new(@controller).instances.count.should == 5
        end
      end

      describe "#destroy!" do
        before do
          Base.clear_all_instances
          @store = Base.new
          @other = Base.new
        end

        it "removes itself from the instances collection" do
          @other.instances.count.should == 2
          @store.destroy!
          @other.instances.count.should == 1
        end
      end

      describe "#collect_all" do
        before do
          Base.clear_all_instances
          @store_one = Base.new
          @store_two = Base.new

          @store_one[:secret] = 'token_one'
          @store_two[:secret] = 'token_two'
        end

        context "called without a block" do
          it "returns an array of values for the specified key from all store instances" do
            secrets = @store_one.collect_all(:secret)
            secrets.should == ['token_one', 'token_two']
          end
        end

        context "called with a block" do
          it "yields each value to the block" do
            @store_one.collect_all(:secret) do |item|
              item.should be_in ['token_one', 'token_two']
            end
          end
        end
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
