require 'rails_helper'

RSpec.describe Ingredients::Parser::SeasoningCollapser do
  describe "#call collapses a pure salt+pepper phrase to the canonical seasoning" do
    [
      "salt and pepper",
      "salt pepper",
      "kosher salt and black pepper",
      "sea salt and cracked pepper",
      "fine sea salt and coarse ground black pepper"
    ].each do |input|
      it("#{input.inspect} → \"salt and pepper\"") { expect(described_class.new(input).call).to eq("salt and pepper") }
    end
  end

  describe "#call leaves a dish seasoned that way untouched (the all-seasoning guard)" do
    [
      "salt and pepper shrimp",
      "salt and pepper chicken"
    ].each do |input|
      it("#{input.inspect} unchanged") { expect(described_class.new(input).call).to eq(input) }
    end
  end

  describe "#call needs both salt and pepper present" do
    {
      "kosher salt"  => "kosher salt",
      "black pepper" => "black pepper",
      "salt"         => "salt"
    }.each do |input, expected|
      it("#{input.inspect} unchanged") { expect(described_class.new(input).call).to eq(expected) }
    end
  end
end
