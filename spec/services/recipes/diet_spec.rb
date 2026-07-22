require 'rails_helper'

RSpec.describe Recipes::Diet do
  def ingredient(meat: false, animal: false)
    Struct.new(:is_meat, :is_animal).new(meat, animal)
  end

  describe ".flags_for" do
    it "is vegetarian and vegan when nothing is meat or animal" do
      expect(described_class.flags_for([ ingredient ])).to eq(is_vegetarian: true, is_vegan: true)
    end

    it "is neither when any ingredient is meat" do
      ings = [ ingredient(meat: true, animal: true), ingredient ]
      expect(described_class.flags_for(ings)).to eq(is_vegetarian: false, is_vegan: false)
    end

    it "is vegetarian but not vegan when an ingredient is animal but not meat" do
      expect(described_class.flags_for([ ingredient(animal: true) ])).to eq(is_vegetarian: true, is_vegan: false)
    end
  end

  describe ".recompute_all_sql" do
    it "builds one bulk UPDATE from the same rule (no drift vs flags_for)" do
      sql = described_class.recompute_all_sql
      expect(sql).to start_with("UPDATE recipes r SET")
      expect(sql).to include("is_vegetarian = NOT EXISTS").and include("i.is_meat")
      expect(sql).to include("is_vegan = NOT EXISTS").and include("i.is_animal")
    end
  end
end
