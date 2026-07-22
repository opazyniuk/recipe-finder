require 'rails_helper'

RSpec.describe Recipes::Importer::CounterCache do
  describe ".recompute_all_sql" do
    let(:egg)    { create(:ingredient, name: "egg") }
    let(:flour)  { create(:ingredient, name: "flour") }
    let(:recipe) { create(:recipe) }

    before do
      create(:recipe_ingredient, recipe: recipe, ingredient: egg, position: 0, raw_text: "egg")
      create(:recipe_ingredient, recipe: recipe, ingredient: flour, position: 1, raw_text: "flour")
      Recipe.where(id: recipe.id).update_all(ingredients_count: 0)
      Ingredient.where(id: [ egg.id, flour.id ]).update_all(recipes_count: 99)
      described_class.recompute_all_sql.each { |sql| ActiveRecord::Base.connection.execute(sql) }
    end

    it "rebuilds recipes.ingredients_count from the links" do
      expect(recipe.reload.ingredients_count).to eq(2)
    end

    it "rebuilds ingredients.recipes_count from the links" do
      expect(egg.reload.recipes_count).to eq(1)
      expect(flour.reload.recipes_count).to eq(1)
    end
  end
end
