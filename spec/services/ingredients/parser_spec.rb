require 'rails_helper'

RSpec.describe Ingredients::Parser do
  describe ".call → assembles name + quantity + unit from the sub-extractors" do
    {
      "1 (8 ounce) package cream cheese, softened" => { name: "cream cheese", quantity: 1.0, unit: "package" },
      "4 cloves garlic, minced"                    => { name: "garlic", quantity: 4.0, unit: "clove" },
      "salt to taste"                              => { name: "salt", quantity: nil, unit: nil }
    }.each do |input, attrs|
      it input.inspect do
        expect(Ingredients::Parser.call(input)).to have_attributes(attrs)
      end
    end
  end

  describe ".call → nil when there is no usable name" do
    [ "", "   ", "1 cup", "2 tablespoons" ].each do |input|
      it("#{input.inspect} → nil") { expect(Ingredients::Parser.call(input)).to be_nil }
    end
  end

  describe ".staple?" do
    %w[salt water butter].each do |name|
      it("is true for #{name}") { expect(Ingredients::Parser.staple?(name)).to be true }
    end

    it "is true for compound staples" do
      expect(Ingredients::Parser.staple?("olive oil")).to be true
      expect(Ingredients::Parser.staple?("salt and pepper")).to be true
    end

    %w[flour sugar chicken].each do |name|
      it("is false for #{name}") { expect(Ingredients::Parser.staple?(name)).to be false }
    end
  end
end
