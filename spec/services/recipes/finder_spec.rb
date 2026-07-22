require 'rails_helper'

RSpec.describe Recipes::Finder do
  let(:egg) { create(:ingredient, name: "egg") }
  let(:pantry) { Pantry.new(selected_ids: [ egg.id ], include_staples: false) }

  def cook_now_recipe(title, ratings)
    create(:recipe, title: title, ratings: ratings).tap do |r|
      create(:recipe_ingredient, recipe: r, ingredient: egg, position: 0, raw_text: "egg")
    end
  end

  describe "pagination" do
    let!(:a) { cook_now_recipe("A", 5.0) }
    let!(:b) { cook_now_recipe("B", 4.0) }
    let!(:c) { cook_now_recipe("C", 3.0) }

    before { stub_const("Recipes::Finder::PER_PAGE", 2) }

    it "returns the first page slice and flags more" do
      result = described_class.call(pantry: pantry, page: 1)

      expect(result.cook_now.map(&:title)).to eq(%w[A B])
      expect(result).to have_attributes(page: 1, per_page: 2, has_more: true, cook_now_total: 3, almost_total: 0)
    end

    it "returns the remainder on the last page with has_more false" do
      result = described_class.call(pantry: pantry, page: 2)

      expect(result.cook_now.map(&:title)).to eq(%w[C])
      expect(result).to have_attributes(page: 2, has_more: false)
    end

    it "does not overlap rows across pages" do
      ids = [ 1, 2 ].flat_map { |p| described_class.call(pantry: pantry, page: p).cook_now.map(&:id) }
      expect(ids).to contain_exactly(a.id, b.id, c.id)
    end

    it "clamps page below 1 and returns empty buckets past the end" do
      expect(described_class.call(pantry: pantry, page: 0).page).to eq(1)
      expect(described_class.call(pantry: pantry, page: 99).cook_now).to be_empty
    end
  end

  describe "bucketing across a page boundary" do
    let(:lemon) { create(:ingredient, name: "lemon") }
    let!(:owned1) { cook_now_recipe("Owned 1", 5.0) }
    let!(:owned2) { cook_now_recipe("Owned 2", 4.0) }
    let!(:almost) do
      create(:recipe, title: "Almost", ratings: 4.9).tap do |r|
        create(:recipe_ingredient, recipe: r, ingredient: egg, position: 0, raw_text: "egg")
        create(:recipe_ingredient, recipe: r, ingredient: lemon, position: 1, raw_text: "lemon")
      end
    end

    before { stub_const("Recipes::Finder::PER_PAGE", 2) }

    it "keeps cook_now contiguous ahead of almost as pages advance" do
      page1 = described_class.call(pantry: pantry, page: 1)
      page2 = described_class.call(pantry: pantry, page: 2)

      expect(page1).to have_attributes(cook_now_total: 2, almost_total: 1)
      expect(page1.cook_now.map(&:title)).to eq([ "Owned 1", "Owned 2" ])
      expect(page1.almost).to be_empty
      expect(page2.cook_now).to be_empty
      expect(page2.almost.map(&:title)).to eq([ "Almost" ])
    end
  end

  describe "ranking" do
    let(:a) { create(:ingredient, name: "a") }
    let(:b) { create(:ingredient, name: "b") }
    let(:c) { create(:ingredient, name: "c") }
    let(:d) { create(:ingredient, name: "d") }
    let(:owned_pantry) { Pantry.new(selected_ids: [ a.id, b.id, c.id, d.id ], include_staples: false) }

    def recipe_with(title, ratings:, have:, missing:)
      create(:recipe, title: title, ratings: ratings).tap do |r|
        (have + missing).each_with_index do |ing, i|
          create(:recipe_ingredient, recipe: r, ingredient: ing, position: i, raw_text: ing.name)
        end
      end
    end

    it "ranks higher coverage first within a missing bucket, ahead of a better rating and a smaller recipe" do
      recipe_with("Low",  ratings: 5.0, have: [ a ],          missing: [ create(:ingredient, name: "x") ])
      recipe_with("High", ratings: 3.0, have: [ a, b, c, d ], missing: [ create(:ingredient, name: "y") ])

      result = described_class.call(pantry: owned_pantry)
      expect(result.almost.map(&:title)).to eq(%w[High Low])
    end

    it "breaks a coverage tie by rating" do
      recipe_with("Weak",   ratings: 3.5, have: [ a, b ], missing: [ create(:ingredient, name: "x") ])
      recipe_with("Strong", ratings: 4.8, have: [ a, b ], missing: [ create(:ingredient, name: "y") ])

      result = described_class.call(pantry: owned_pantry)
      expect(result.almost.map(&:title)).to eq(%w[Strong Weak])
    end
  end

  describe "difficulty filter respects the missing-count gate (OR-precedence regression)" do
    let(:owned) { Array.new(13) { |i| create(:ingredient, name: "own#{i}") } }
    let(:pantry) { Pantry.new(selected_ids: owned.map(&:id), include_staples: false) }

    def hard_recipe(title, ingredients)
      create(:recipe, title: title, total_time: 30).tap do |r|
        ingredients.each_with_index { |ing, i| create(:recipe_ingredient, recipe: r, ingredient: ing, position: i, raw_text: ing.name) }
      end
    end

    it "keeps a cookable hard recipe but excludes a 14-ingredient one the pantry can't reach" do
      hard_recipe("Cookable Hard", owned + [ create(:ingredient, name: "rare") ])
      hard_recipe("Unreachable Hard", [ owned.first ] + Array.new(13) { |i| create(:ingredient, name: "miss#{i}") })

      titles = described_class.call(pantry: pantry, difficulty: "hard").then { |r| (r.cook_now + r.almost).map(&:title) }
      expect(titles).to include("Cookable Hard")
      expect(titles).not_to include("Unreachable Hard")
    end
  end

  describe "difficulty label and filter stay consistent on NULL cook time" do
    it "labels an unknown-cook-time recipe medium and the medium filter still returns it" do
      egg = create(:ingredient, name: "egg")
      ings = [ egg ] + Array.new(9) { |i| create(:ingredient, name: "m#{i}") }
      recipe = create(:recipe, title: "No Time", total_time: nil)
      ings.each_with_index { |ing, i| create(:recipe_ingredient, recipe: recipe, ingredient: ing, position: i, raw_text: ing.name) }
      pantry = Pantry.new(selected_ids: ings.map(&:id), include_staples: false)

      expect(described_class.call(pantry: pantry).cook_now.map(&:difficulty)).to eq([ "medium" ])
      expect(described_class.call(pantry: pantry, difficulty: "medium").cook_now.map(&:title)).to eq([ "No Time" ])
    end
  end

  it "returns an empty result for an empty pantry" do
    result = described_class.call(pantry: Pantry.new(selected_ids: []))
    expect(result).to have_attributes(cook_now: [], almost: [], cook_now_total: 0, almost_total: 0, has_more: false)
  end
end
