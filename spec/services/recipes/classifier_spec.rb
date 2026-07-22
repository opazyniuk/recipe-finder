require 'rails_helper'

RSpec.describe Recipes::Classifier do
  def classify(name) = described_class.new(name)

  describe "#meat?" do
    %w[beef chicken bacon salmon shrimp gelatin].each do |name|
      it("is true for #{name}") { expect(classify(name).meat?).to be true }
    end

    it "catches compound meat names" do
      expect(classify("chicken broth").meat?).to be true
      expect(classify("ground beef").meat?).to be true
    end

    %w[tofu lentil egg milk eggplant].each do |name|
      it("is false for #{name}") { expect(classify(name).meat?).to be false }
    end
  end

  describe "#animal?" do
    it "is true for meat, dairy, egg, and honey" do
      expect(classify("chicken").animal?).to be true
      expect(classify("cheddar cheese").animal?).to be true
      expect(classify("egg").animal?).to be true
      expect(classify("honey").animal?).to be true
    end

    it "treats plant milks and nut butters as vegan-safe" do
      expect(classify("coconut milk").animal?).to be false
      expect(classify("almond milk").animal?).to be false
      expect(classify("peanut butter").animal?).to be false
    end

    it "is false for plants and is not fooled by eggplant" do
      expect(classify("tofu").animal?).to be false
      expect(classify("eggplant").animal?).to be false
    end
  end
end
