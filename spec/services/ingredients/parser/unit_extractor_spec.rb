require 'rails_helper'

RSpec.describe Ingredients::Parser::UnitExtractor do
  describe ".call (ignores parenthetical sizes)" do
    {
      "1 (8 ounce) package cream cheese" => "package",
      "3 ½ teaspoons baking powder"      => "teaspoon",
      "4 cloves garlic"                  => "clove"
    }.each do |input, expected|
      it "#{input.inspect} → #{expected.inspect}" do
        expect(Ingredients::Parser::UnitExtractor.call(input)).to eq(expected)
      end
    end

    it "is nil when there is no unit" do
      expect(Ingredients::Parser::UnitExtractor.call("2 lemons, sliced")).to be_nil
    end
  end
end
