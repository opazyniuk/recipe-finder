require 'rails_helper'

RSpec.describe Recipes::Cuisine do
  describe ".for" do
    it "maps cuisine categories" do
      expect(described_class.for("Mexican Recipes")).to eq("Mexican")
      expect(described_class.for("Italian Recipes")).to eq("Italian")
    end

    it "ignores dish categories and dish-named false positives" do
      expect(described_class.for("Chicken Breasts")).to be_nil
      expect(described_class.for("French Bread")).to be_nil
      expect(described_class.for(nil)).to be_nil
    end
  end
end
