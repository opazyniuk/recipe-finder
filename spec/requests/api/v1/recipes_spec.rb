require 'rails_helper'

RSpec.describe "Api::V1::Recipes", type: :request do
  let(:pasta)   { create(:ingredient, name: "pasta") }
  let(:garlic)  { create(:ingredient, name: "garlic") }
  let(:butter)  { create(:ingredient, :staple, name: "butter") }
  let(:lemon)   { create(:ingredient, name: "lemon") }
  let(:cream)   { create(:ingredient, name: "cream") }
  let(:onion)   { create(:ingredient, name: "onion") }
  let(:vinegar) { create(:ingredient, name: "vinegar") }

  def link(recipe, *ingredients)
    ingredients.each_with_index do |ing, i|
      create(:recipe_ingredient, recipe: recipe, ingredient: ing, position: i, raw_text: ing.name)
    end
  end

  def search_titles(response)
    json = JSON.parse(response.body)
    (json["cook_now"] + json["almost"]).map { |r| r["title"] }
  end

  let!(:garlic_pasta) { create(:recipe, title: "Garlic Pasta", ratings: 4.5).tap { |r| link(r, pasta, garlic, butter) } }
  let!(:lemon_pasta) { create(:recipe, title: "Lemon Garlic Pasta", ratings: 4.0).tap { |r| link(r, pasta, garlic, lemon) } }
  let!(:everything) { create(:recipe, title: "Everything Pasta").tap { |r| link(r, pasta, lemon, cream, onion, vinegar) } }

  describe "GET /api/v1/recipes/search" do
    it "buckets results into cook_now and almost, excluding missing > 2" do
      get "/api/v1/recipes/search", params: { ingredient_ids: [ pasta.id, garlic.id ], include_staples: true }

      json = JSON.parse(response.body)
      expect(json["cook_now"].map { |r| r["title"] }).to eq([ "Garlic Pasta" ])
      expect(json["almost"].map { |r| r["title"] }).to eq([ "Lemon Garlic Pasta" ])

      cook = json["cook_now"].first
      expect(cook).to include("have_count" => 3, "total_count" => 3, "missing_count" => 0, "missing_names" => [])

      almost = json["almost"].first
      expect(almost).to include("have_count" => 2, "total_count" => 3, "missing_count" => 1, "missing_names" => [ "lemon" ])
    end

    it "counts staples as missing when the toggle is off" do
      get "/api/v1/recipes/search", params: { ingredient_ids: [ pasta.id, garlic.id ], include_staples: false }

      json = JSON.parse(response.body)
      expect(json["cook_now"]).to be_empty
      titles = json["almost"].map { |r| r["title"] }
      expect(titles).to include("Garlic Pasta")
      garlic_row = json["almost"].find { |r| r["title"] == "Garlic Pasta" }
      expect(garlic_row["missing_names"]).to eq([ "butter" ])
    end

    it "returns empty buckets for an empty pantry" do
      get "/api/v1/recipes/search", params: { ingredient_ids: [] }
      json = JSON.parse(response.body)
      expect(json["cook_now"]).to eq([])
      expect(json["almost"]).to eq([])
    end

    it "exposes pagination metadata" do
      get "/api/v1/recipes/search", params: { ingredient_ids: [ pasta.id, garlic.id ], include_staples: true }

      json = JSON.parse(response.body)
      expect(json).to include("page" => 1, "per_page" => 24, "has_more" => false, "cook_now_total" => 1, "almost_total" => 1)
    end

    it "ignores a client-supplied per_page; page size is fixed server-side" do
      get "/api/v1/recipes/search", params: { ingredient_ids: [ pasta.id, garlic.id ], include_staples: true, per_page: 1 }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("per_page" => 24)
    end
  end

  describe "GET /api/v1/recipes/search (difficulty filter)" do
    let(:egg) { create(:ingredient, name: "egg") }
    let!(:quick) { create(:recipe, title: "Quick Eggs", total_time: 20).tap { |r| link(r, egg) } }
    let!(:slow)  { create(:recipe, title: "Slow Eggs", total_time: 90).tap { |r| link(r, egg) } }

    it "returns only easy recipes when difficulty=easy" do
      get "/api/v1/recipes/search", params: { ingredient_ids: [ egg.id ], difficulty: "easy" }
      expect(search_titles(response)).to contain_exactly("Quick Eggs")
    end

    it "returns only hard recipes when difficulty=hard" do
      get "/api/v1/recipes/search", params: { ingredient_ids: [ egg.id ], difficulty: "hard" }
      expect(search_titles(response)).to contain_exactly("Slow Eggs")
    end

    it "tags each recipe with a difficulty and ignores an unknown value (no filter)" do
      get "/api/v1/recipes/search", params: { ingredient_ids: [ egg.id ], difficulty: "bogus" }
      rows = JSON.parse(response.body).values_at("cook_now", "almost").flatten
      expect(rows.map { |r| r["title"] }).to contain_exactly("Quick Eggs", "Slow Eggs")
      expect(rows.map { |r| r["difficulty"] }).to contain_exactly("easy", "hard")
    end
  end

  describe "GET /api/v1/recipes/search (diet / rating filters)" do
    let(:egg) { create(:ingredient, name: "egg") }
    let!(:veg)   { create(:recipe, title: "Veggie", is_vegetarian: true, is_vegan: false, ratings: 4.8).tap { |r| link(r, egg) } }
    let!(:vegan) { create(:recipe, title: "Vegan Bowl", is_vegetarian: true, is_vegan: true, ratings: 3.2).tap { |r| link(r, egg) } }
    let!(:meaty) { create(:recipe, title: "Carne", is_vegetarian: false, is_vegan: false, ratings: 4.9).tap { |r| link(r, egg) } }

    it "filters vegetarian recipes" do
      get "/api/v1/recipes/search", params: { ingredient_ids: [ egg.id ], diet: "vegetarian" }
      expect(search_titles(response)).to contain_exactly("Veggie", "Vegan Bowl")
    end

    it "filters vegan recipes" do
      get "/api/v1/recipes/search", params: { ingredient_ids: [ egg.id ], diet: "vegan" }
      expect(search_titles(response)).to contain_exactly("Vegan Bowl")
    end

    it "filters by minimum rating" do
      get "/api/v1/recipes/search", params: { ingredient_ids: [ egg.id ], min_rating: 4.5 }
      expect(search_titles(response)).to contain_exactly("Veggie", "Carne")
    end
  end

  describe "GET /api/v1/recipes/:id" do
    it "returns the recipe with have/missing flags relative to the pantry" do
      get "/api/v1/recipes/#{garlic_pasta.id}", params: { ingredient_ids: [ pasta.id ], include_staples: false }

      recipe = JSON.parse(response.body)
      expect(recipe["title"]).to eq("Garlic Pasta")
      flags = recipe["ingredients"].to_h { |i| [ i["name"], i["is_available"] ] }
      expect(flags).to eq("pasta" => true, "garlic" => false, "butter" => false)
    end

    it "404s for a missing recipe" do
      get "/api/v1/recipes/0"
      expect(response).to have_http_status(:not_found)
    end
  end
end
