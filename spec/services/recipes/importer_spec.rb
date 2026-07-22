require 'rails_helper'

RSpec.describe Recipes::Importer do
  let(:fixture) do
    [
      {
        "title" => "Garlic Butter Pasta", "image" => "http://img/1.jpg",
        "category" => "Pasta", "author" => "A", "prep_time" => 5, "cook_time" => 15,
        "ratings" => 4.8,
        "ingredients" => [
          "8 ounces pasta",
          "4 cloves garlic, minced",
          "2 tablespoons butter",
          "1 teaspoon salt",
          "2 cloves garlic, sliced"
        ]
      },
      {
        "title" => "Cheesy Bread", "image" => "http://img/2.jpg",
        "category" => "Bread", "author" => "B", "prep_time" => 10, "cook_time" => nil,
        "ratings" => 4.2,
        "ingredients" => [
          "1 loaf bread",
          "1 cup shredded Cheddar cheese",
          "2 tablespoons butter"
        ]
      }
    ]
  end

  def import!
    Recipes::Importer.call(io: StringIO.new(JSON.generate(fixture)))
  end

  it "imports recipes, canonical ingredients, and links" do
    result = import!
    expect(result.recipes).to eq(2)
    expect(result.ingredients).to eq(6)
    expect(result.links).to eq(7)
  end

  it "dedupes a shared ingredient into one canonical row" do
    import!
    expect(Ingredient.where(name: "butter").count).to eq(1)
  end

  it "dedupes a repeated canonical ingredient within a recipe" do
    import!
    pasta = Recipe.find_by(title: "Garlic Butter Pasta")
    expect(pasta.ingredients.where(name: "garlic").count).to eq(1)
  end

  it "flags staples from the curated list" do
    import!
    expect(Ingredient.find_by(name: "butter")).to be_is_staple
    expect(Ingredient.find_by(name: "salt")).to be_is_staple
    expect(Ingredient.find_by(name: "pasta")).not_to be_is_staple
  end

  it "recomputes counter caches (no N+1)" do
    import!
    expect(Ingredient.find_by(name: "butter").recipes_count).to eq(2)
    expect(Recipe.find_by(title: "Garlic Butter Pasta").ingredients_count).to eq(4)
  end

  it "stores parsed quantity/unit and preserves the original line" do
    import!
    link = RecipeIngredient.joins(:ingredient).find_by(ingredients: { name: "pasta" })
    expect(link.quantity).to eq(8.0)
    expect(link.unit).to eq("ounce")
    expect(link.raw_text).to eq("8 ounces pasta")
  end

  it "is idempotent" do
    import!
    expect(import!).to eq(:already_seeded)
    expect(Recipe.count).to eq(2)
  end

  it "unwraps the dead meredith image proxy to the direct URL" do
    inner = "https://images.media-allrecipes.com/userphotos/9252392.jpg"
    proxy = "https://imagesvc.meredithcorp.io/v3/mm/image?#{URI.encode_www_form([ [ 'url', inner ] ])}"
    io = StringIO.new(JSON.generate([ { "title" => "X", "image" => proxy, "ingredients" => [ "1 cup flour" ] } ]))

    Recipes::Importer.call(io: io)

    expect(Recipe.find_by(title: "X").image_url).to eq(inner)
  end

  it "reports how many ingredient lines were dropped as unparseable" do
    io = StringIO.new(JSON.generate([
      { "title" => "Sparse", "ingredients" => [ "1 cup flour", "1 teaspoon", "2 cups" ] }
    ]))
    result = Recipes::Importer.call(io: io)
    expect(result.dropped_lines).to eq(2)
  end

  it "treats a missing prep+cook time as unknown (nil), never 0" do
    io = StringIO.new(JSON.generate([
      { "title" => "Zeroed", "prep_time" => 0, "cook_time" => 0, "ingredients" => [ "1 cup flour" ] },
      { "title" => "PrepOnly", "prep_time" => 15, "cook_time" => nil, "ingredients" => [ "1 cup flour" ] }
    ]))
    Recipes::Importer.call(io: io)
    expect(Recipe.find_by(title: "Zeroed").total_time).to be_nil
    expect(Recipe.find_by(title: "PrepOnly").total_time).to eq(15)
  end

  it "collapses a potato variety so a pantry 'potato' matches the recipe" do
    io = StringIO.new(JSON.generate([
      { "title" => "Spud Bake", "ingredients" => [ "2 baking potatoes" ] }
    ]))
    Recipes::Importer.call(io: io)

    potato = Ingredient.find_by(name: "potato")
    expect(potato).to be_present
    expect(Ingredient.find_by(name: "baking potato")).to be_nil

    result = Recipes::Finder.call(pantry: Pantry.new(selected_ids: [ potato.id ], include_staples: false))
    expect((result.cook_now + result.almost).map(&:title)).to include("Spud Bake")
  end

  it "dedupes multiple potato varieties in one recipe and stays searchable by 'potato'" do
    io = StringIO.new(JSON.generate([
      { "title" => "Double Spud", "ingredients" => [ "2 russet potatoes", "1 cup baby potatoes, halved" ] }
    ]))
    Recipes::Importer.call(io: io)

    recipe = Recipe.find_by(title: "Double Spud")
    expect(recipe.ingredients.pluck(:name)).to eq([ "potato" ])
    expect(recipe.ingredients_count).to eq(1)

    potato = Ingredient.find_by(name: "potato")
    match = Recipes::Finder.call(pantry: Pantry.new(selected_ids: [ potato.id ], include_staples: false))
                           .cook_now.find { |m| m.title == "Double Spud" }
    expect(match).to be_present
    expect(match.have_count).to eq(match.total_count)
    expect(match.missing_names).to be_empty
  end

  it "keeps sweet potato distinct so a pantry 'potato' does not match a sweet-potato recipe" do
    io = StringIO.new(JSON.generate([
      { "title" => "Plain Spud", "ingredients" => [ "1 baking potato" ] },
      { "title" => "Sweet Spud", "ingredients" => [ "2 sweet potatoes" ] }
    ]))
    Recipes::Importer.call(io: io)

    potato = Ingredient.find_by(name: "potato")
    expect(Ingredient.find_by(name: "sweet potato")).to be_present

    titles = Recipes::Finder.call(pantry: Pantry.new(selected_ids: [ potato.id ], include_staples: false))
                            .then { |r| (r.cook_now + r.almost).map(&:title) }
    expect(titles).to include("Plain Spud")
    expect(titles).not_to include("Sweet Spud")
  end
end
