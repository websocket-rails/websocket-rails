require 'spec_helper'


class ComplexProductController < WebsocketRails::BaseController

  def simplify
    true
  end

end


module WebsocketRails

  describe TargetValidator do

    describe 'validate_target' do

      it 'should raise an error when target class is not supported' do
        expect{TargetValidator.validate_target(50)}.to raise_error
      end

      it 'should raise if passed hash does not contain the to: key' do
        expect{TargetValidator.validate_target(from: ComplexProductController, with_method: :simplify)}.to raise_error
      end

      it 'should raise if passed hash does not contain the with_method: key' do
        expect{TargetValidator.validate_target(to: ComplexProductController, without_method: :simplify)}.to raise_error
      end

      it 'should raise if the string is not in the correct format' do
        expect{TargetValidator.validate_target('malformed_string')}.to raise_error
        expect{TargetValidator.validate_target('very#malformed#string')}.to raise_error
      end

      it 'should raise if the class specified in the String does not exist' do
        expect{TargetValidator.validate_target('my_non_existent#my_method')}.to raise_error
      end

      it 'should parse correctly a well-formed Hash' do
        TargetValidator::validate_target(to: ComplexProductController, with_method: :simplify).should == [ComplexProductController, :simplify]
      end

      it 'should parse correctly a well-formed String' do
        TargetValidator::validate_target('complex_product#simplify').should == [ComplexProductController, :simplify]
      end

    end


  end



end