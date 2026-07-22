require 'rails_helper'

RSpec.describe Recipes::UkrainianSeeder do
  let(:records) do
    [
      { title: "Test Borscht", category: "Soup", image_url: "http://img/borscht.jpg", prep_time: 10, cook_time: 20,
        ingredients: [ "1 pound beef chuck", "2 russet potatoes", "1 cup baby potatoes", "1 onion, chopped" ] },
      { title: "Test Deruny", category: "Breakfast", image_url: "http://img/deruny.jpg", prep_time: 10, cook_time: 10,
        ingredients: [ "3 potatoes, grated", "1 egg", "1 onion" ] },
      { title: "Test Uzvar", category: "Drink", image_url: "http://img/uzvar.jpg", prep_time: 5, cook_time: 20,
        ingredients: [ "1/4 cup raisins", "8 cups water" ] }
    ]
  end

  it "creates the recipes and is idempotent (re-run upserts, never duplicates)" do
    expect { described_class.call(records) }.to change(Recipe, :count).by(3)
    expect { described_class.call(records) }.not_to change(Recipe, :count)
    expect { described_class.call(records) }.not_to change(RecipeIngredient, :count)
  end

  it "stamps every record with the Ukrainian cuisine, top rating, and its picture" do
    described_class.call(records)

    records.each do |data|
      recipe = Recipe.find_by!(title: data[:title])
      expect(recipe.cuisine).to eq("Ukrainian")
      expect(recipe.ratings).to eq(5.0)
      expect(recipe.image_url).to eq(data[:image_url])
    end
  end

  it "classifies diet from the English ingredient names" do
    described_class.call(records)

    expect(Recipe.find_by(title: "Test Borscht").is_vegetarian).to be(false)
    deruny = Recipe.find_by(title: "Test Deruny")
    expect(deruny.is_vegetarian).to be(true)
    expect(deruny.is_vegan).to be(false)
    expect(Recipe.find_by(title: "Test Uzvar").is_vegan).to be(true)
  end

  it "dedupes ingredient varieties that collapse to the same canonical" do
    described_class.call(records)

    borscht = Recipe.find_by(title: "Test Borscht")
    expect(borscht.ingredients.pluck(:name)).to contain_exactly("beef chuck", "potato", "onion")
    expect(borscht.ingredients_count).to eq(3)
  end

  it "reuses an existing canonical ingredient instead of duplicating it" do
    potato = Ingredient.create!(name: "potato")

    described_class.call(records)

    expect(Ingredient.where(name: "potato").count).to eq(1)
    expect(potato.reload.recipes_count).to be > 0
  end

  it "makes a dish searchable by a pantry of its English ingredients" do
    described_class.call(records)
    ids = Ingredient.where(name: %w[potato onion egg]).pluck(:id)

    result = Recipes::Finder.call(pantry: Pantry.new(selected_ids: ids, include_staples: true))
    expect((result.cook_now + result.almost).map(&:title)).to include("Test Deruny")
  end
end
