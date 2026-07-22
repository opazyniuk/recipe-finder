require 'rails_helper'

RSpec.describe Recipe, type: :model do
  it "has a valid factory" do
    expect(build(:recipe)).to be_valid
  end

  it "requires a title" do
    expect(build(:recipe, title: nil)).not_to be_valid
  end

  it "exposes ingredients through recipe_ingredients" do
    ri = create(:recipe_ingredient)
    expect(ri.recipe.ingredients).to include(ri.ingredient)
  end
end
