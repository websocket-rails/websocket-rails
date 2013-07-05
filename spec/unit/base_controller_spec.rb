require "spec_helper"

module WebsocketRails
  describe BaseController do

    class TestClass; end;

    describe ".inherited" do
      context "with Rails version 3" do
        before do
          Rails.stub(:version).and_return("3.2.13")
        end

        it "should call unloadable on the inherited class" do
          Object.should_receive(:unloadable).with(TestClass)
          BaseController.inherited(TestClass)
        end
      end

      context "with Rails version 4" do
        before do
          Rails.stub(:version).and_return("4.0.0")
        end

        it "should call unloadable on the inherited class" do
          Object.should_not_receive(:unloadable).with(TestClass)
          BaseController.inherited(TestClass)
        end
      end
    end

  end
end
