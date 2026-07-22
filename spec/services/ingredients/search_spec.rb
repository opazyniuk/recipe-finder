require 'rails_helper'

RSpec.describe Ingredients::Search do
  describe ".autocomplete" do
    let!(:chicken)  { create(:ingredient, name: "chicken", recipes_count: 50) }
    let!(:chickpea) { create(:ingredient, name: "chickpea", recipes_count: 5) }
    let!(:jalapeno) { create(:ingredient, name: "jalapeno", recipes_count: 10) }
    let!(:flour)    { create(:ingredient, name: "all purpose flour", recipes_count: 20) }

    def names_for(query)
      described_class.autocomplete(query).map(&:name)
    end

    it "prefix-matches, ordered by popularity" do
      expect(names_for("chick")).to eq(%w[chicken chickpea])
    end

    it "folds accented input to the de-accented stored names" do
      expect(names_for("jalapeño")).to include("jalapeno")
    end

    it "strips characters outside the [a-z ] alphabet, then prefix-matches" do
      expect(names_for("chick%")).to eq(%w[chicken chickpea])
    end

    it "does not let % act as a LIKE wildcard (normalize neutralizes it)" do
      expect(names_for("c%n")).not_to include("chicken")
    end

    it "folds hyphens to spaces to match the space-separated names" do
      expect(names_for("all-purpose")).to include("all purpose flour")
    end

    it "collapses surrounding and repeated whitespace" do
      expect(names_for("  chick   ")).to eq(%w[chicken chickpea])
    end

    it "returns an empty relation when the query normalizes to blank" do
      expect(described_class.autocomplete("123 %$#").to_a).to be_empty
    end
  end
end
