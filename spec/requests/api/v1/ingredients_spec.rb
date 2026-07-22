require 'rails_helper'

RSpec.describe "Api::V1::Ingredients", type: :request do
  describe "GET /api/v1/ingredients" do
    let!(:chicken)  { create(:ingredient, name: "chicken", recipes_count: 50) }
    let!(:chickpea) { create(:ingredient, name: "chickpea", recipes_count: 5) }
    let!(:chocolate) { create(:ingredient, name: "chocolate", recipes_count: 30) }

    it "returns [] for a blank query" do
      get "/api/v1/ingredients", params: { query: "" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns prefix matches ordered by popularity" do
      get "/api/v1/ingredients", params: { query: "chick" }
      names = JSON.parse(response.body).map { |i| i["name"] }
      expect(names).to eq(%w[chicken chickpea])
    end

    it "tolerates a typo via pg_trgm fuzzy matching" do
      get "/api/v1/ingredients", params: { query: "chiken" }
      names = JSON.parse(response.body).map { |i| i["name"] }
      expect(names).to include("chicken")
    end

    it "exposes the fields the picker needs" do
      get "/api/v1/ingredients", params: { query: "chicken" }
      expect(JSON.parse(response.body).first).to include(
        "id" => chicken.id, "name" => "chicken", "recipes_count" => 50, "is_staple" => false
      )
    end

    it "neutralizes SQL wildcards so they cannot act as a match-all" do
      get "/api/v1/ingredients", params: { query: "%" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])

      get "/api/v1/ingredients", params: { query: "chick%_" }
      names = JSON.parse(response.body).map { |i| i["name"] }
      expect(names).to eq(%w[chicken chickpea])
    end
  end

  describe "GET /api/v1/ingredients/popular" do
    it "returns top non-staple ingredients by popularity, excluding staples" do
      create(:ingredient, name: "common", recipes_count: 100)
      create(:ingredient, name: "rare", recipes_count: 1)
      create(:ingredient, :staple, name: "salt", recipes_count: 999)

      get "/api/v1/ingredients/popular"

      names = JSON.parse(response.body).map { |i| i["name"] }
      expect(names.first).to eq("common")
      expect(names).not_to include("salt")
    end
  end
end
