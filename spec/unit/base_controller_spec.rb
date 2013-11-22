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

    describe "before actions" do
      class BeforeActionController < WebsocketRails::BaseController
        before_action                             { self.before_array << :all }
        before_action(:only => :only)             { self.before_array << :only_1 }
        before_action(:only => :except)           { self.before_array << :only_2 }
        before_action(:only => [:main, :only])    { self.before_array << :only_3 }
        before_action(:only => [:except, :only])  { self.before_array << :only_4 }
        before_action(:except => :except)         { self.before_array << :except_1 }
        before_action(:except => :only)           { self.before_array << :except_2 }
        before_action(:except => [:main, :except]){ self.before_array << :except_3 }
        before_action(:except => [:only, :except]){ self.before_array << :except_4 }

        attr_accessor :before_array

        def initialize
          @before_array = []
        end
        def main;end
        def only;end
        def except;end
      end

      let(:controller) { BeforeActionController.new }
      it 'should handle before_action with no args' do
        controller.instance_variable_set :@_action_name, 'main'
        controller.process_action(:main, nil)
        controller.before_array.should == [:all, :only_3, :except_1, :except_2, :except_4]
      end

      it 'should handle before_action with :only flag' do
        controller.instance_variable_set :@_action_name, 'only'
        controller.process_action(:only, nil)
        controller.before_array.should == [:all, :only_1, :only_3, :only_4, :except_1, :except_3]
      end

      it 'should handle before_action with :except flag' do
        controller.instance_variable_set :@_action_name, 'except'
        controller.process_action(:except, nil)
        controller.before_array.should == [:all, :only_2, :only_4, :except_2]
      end
    end
  end
end
