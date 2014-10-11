require 'spec_helper'

module WebsocketRails
  module DataStore
    describe Base do
      it "extends Hash" do
        expect(subject).to be_a Hash
      end

      it "allows indifferent access" do
        subject['key'] = true
        expect(subject[:key]).to eq(true)
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

          expect(store_one.instances.count).to eq(2)
          expect(store_two.instances.count).to eq(2)
        end

        it "separates instances based on class name" do
          2.times { Connection.new(@connection) }
          4.times { Controller.new(@controller) }

          expect(Connection.new(@connection).instances.count).to eq(3)
          expect(Controller.new(@controller).instances.count).to eq(5)
        end
      end

      describe "#destroy!" do
        before do
          Base.clear_all_instances
          @store = Base.new
          @other = Base.new
        end

        it "removes itself from the instances collection" do
          expect(@other.instances.count).to eq(2)
          @store.destroy!
          expect(@other.instances.count).to eq(1)
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
            expect(secrets).to eq(['token_one', 'token_two'])
          end
        end

        context "called with a block" do
          it "yields each value to the block" do
            @store_one.collect_all(:secret) do |item|
              expect(item).to be_in ['token_one', 'token_two']
            end
          end
        end
      end
    end

    describe Connection do
      before do
        @connection = double('connection')
        allow(@connection).to receive(:client_id).and_return(1)
      end

      let(:subject) { DataStore::Connection.new(@connection) }

      it "stores a reference to it's connection" do
        expect(subject.connection).to eq(@connection)
      end
    end

    describe Controller do
      before do
        @controller = double('controller')
      end

      let(:subject) { DataStore::Controller.new(@controller) }

      it "stores a reference to it's controller" do
        expect(subject.controller).to eq(@controller)
      end
    end
  end

end
