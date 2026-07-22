require 'rails_helper'

RSpec.describe Ingredient, type: :model do
  it "has a valid factory" do
    expect(build(:ingredient)).to be_valid
  end

  describe "validations" do
    it "requires a name" do
      expect(build(:ingredient, name: nil)).not_to be_valid
    end

    it "requires a unique name" do
      create(:ingredient, name: "garlic")
      expect(build(:ingredient, name: "garlic")).not_to be_valid
    end
  end

  describe "associations" do
    it "exposes recipes through recipe_ingredients" do
      ri = create(:recipe_ingredient)
      expect(ri.ingredient.recipes).to include(ri.recipe)
    end
  end

  describe ".staples" do
    it "returns only staple ingredients" do
      staple = create(:ingredient, :staple)
      create(:ingredient)
      expect(Ingredient.staples).to contain_exactly(staple)
    end
  end
end
