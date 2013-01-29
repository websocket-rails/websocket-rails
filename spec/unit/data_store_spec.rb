require 'spec_helper'

module WebsocketRails
  describe DataStore do
    let(:attribute) {"example_attribute"}
    let(:value)     {1}

    before(:each) do
      @base = double('base_controller')
      @base.stub(:client_id).and_return(1)
      @data_store = DataStore.new(@base)
    end
    
    it "loads up" do
      @data_store.present?.should be_true
    end

    describe "#[]" do
      context "with an undefined attribute" do
        it "returns nil" do
          @data_store[attribute].should be_nil
        end
      end

      context "with a defined attribute" do
        it "returns its value" do
          @data_store[attribute] = value
          @data_store[attribute].should == value
        end
      end
    end

    describe "#[]=" do
      it "returns the value" do
        (@data_store[attribute]=value).should == value
      end
    end
  end
end
