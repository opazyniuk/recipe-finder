require 'rails_helper'

RSpec.describe RecipeIngredient, type: :model do
  it "has a valid factory" do
    expect(build(:recipe_ingredient)).to be_valid
  end

  it "requires raw_text" do
    expect(build(:recipe_ingredient, raw_text: nil)).not_to be_valid
  end

  it "is unique per (recipe, ingredient)" do
    existing = create(:recipe_ingredient)
    dup = build(:recipe_ingredient, recipe: existing.recipe, ingredient: existing.ingredient)
    expect(dup).not_to be_valid
  end

  it "maintains counter caches on both sides" do
    recipe = create(:recipe)
    ingredient = create(:ingredient)
    expect {
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient)
    }.to change { recipe.reload.ingredients_count }.by(1)
      .and change { ingredient.reload.recipes_count }.by(1)
  end
end
