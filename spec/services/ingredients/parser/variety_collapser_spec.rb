require 'rails_helper'

RSpec.describe Ingredients::Parser::VarietyCollapser do
  describe "#call collapses a variety down to its base ingredient" do
    {
      "baking potato"    => "potato",
      "russet potato"    => "potato",
      "baby red potato"  => "potato",
      "white mushroom"   => "mushroom",
      "cremini mushroom" => "mushroom",
      "roma tomato"      => "tomato"
    }.each do |input, expected|
      it("#{input.inspect} → #{expected.inspect}") { expect(described_class.new(input).call).to eq(expected) }
    end
  end

  describe "#call leaves anything else untouched" do
    [
      "potato",
      "sweet potato",
      "cherry tomato",
      "white onion",
      "portobello mushroom cap"
    ].each do |input|
      it("#{input.inspect} unchanged") { expect(described_class.new(input).call).to eq(input) }
    end
  end

  describe "#call returns nil for a blank result" do
    [ "", "   " ].each do |input|
      it("#{input.inspect} → nil") { expect(described_class.new(input).call).to be_nil }
    end
  end
end
