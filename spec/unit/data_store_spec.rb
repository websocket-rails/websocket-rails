require 'spec_helper'

module WebsocketRails
  describe DataStore do
    before(:each) do
      @base = double('base_controller')
      @base.stub(:client_id).and_return(1)
    end
    
    it "loads up" do
      data_store = DataStore.new(@base)
      data_store.present?.should be_true
    end
  end
end
