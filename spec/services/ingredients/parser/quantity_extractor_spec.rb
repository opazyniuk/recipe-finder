require 'rails_helper'

RSpec.describe Ingredients::Parser::QuantityExtractor do
  describe ".call (handles the '3 ½ → 3.5' pitfall)" do
    {
      "3 ½ teaspoons baking powder"      => 3.5,
      "1 1/2 cups flour"                 => 1.5,
      "½ cup milk"                       => 0.5,
      "0.5 cup sugar"                    => 0.5,
      "2 lemons, sliced"                 => 2.0,
      "1 (8 ounce) package cream cheese" => 1.0
    }.each do |input, expected|
      it "#{input.inspect} → #{expected}" do
        expect(Ingredients::Parser::QuantityExtractor.call(input)).to eq(expected)
      end
    end

    it "is nil when there is no leading amount" do
      expect(Ingredients::Parser::QuantityExtractor.call("salt to taste")).to be_nil
    end
  end
end
