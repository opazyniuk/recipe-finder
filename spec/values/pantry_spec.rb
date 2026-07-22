require 'rails_helper'

RSpec.describe Pantry do
  let!(:tomato) { create(:ingredient, name: "tomato") }
  let!(:cheese) { create(:ingredient, name: "cheese") }
  let!(:salt)   { create(:ingredient, :staple, name: "salt") }
  let!(:oil)    { create(:ingredient, :staple, name: "oil") }

  describe "#selected_ids" do
    it "casts to integers and dedups" do
      pantry = Pantry.new(selected_ids: [ tomato.id.to_s, tomato.id.to_s, cheese.id.to_s ])
      expect(pantry.selected_ids).to eq([ tomato.id, cheese.id ])
    end

    it "is empty when nil" do
      expect(Pantry.new(selected_ids: nil).selected_ids).to eq([])
    end
  end

  describe "#available_ids" do
    it "adds every staple when staples are assumed" do
      pantry = Pantry.new(selected_ids: [ tomato.id ], include_staples: true)
      expect(pantry.available_ids).to contain_exactly(tomato.id, salt.id, oil.id)
    end

    it "does not duplicate a selected ingredient that is itself a staple" do
      pantry = Pantry.new(selected_ids: [ salt.id ], include_staples: true)
      expect(pantry.available_ids).to contain_exactly(salt.id, oil.id)
    end

    it "is exactly the selected ids when staples are off" do
      pantry = Pantry.new(selected_ids: [ tomato.id ], include_staples: false)
      expect(pantry.available_ids).to eq([ tomato.id ])
    end
  end

  describe "include_staples casting" do
    it "treats 'true', '1' and omitted as on" do
      expect(Pantry.new(selected_ids: [ tomato.id ], include_staples: "true").available_ids).to include(salt.id)
      expect(Pantry.new(selected_ids: [ tomato.id ], include_staples: "1").available_ids).to include(salt.id)
      expect(Pantry.new(selected_ids: [ tomato.id ]).available_ids).to include(salt.id)
    end

    it "treats 'false' and nil as off" do
      expect(Pantry.new(selected_ids: [ tomato.id ], include_staples: "false").available_ids).not_to include(salt.id)
      expect(Pantry.new(selected_ids: [ tomato.id ], include_staples: nil).available_ids).not_to include(salt.id)
    end
  end

  describe "#includes?" do
    it "is true for a selected ingredient" do
      expect(Pantry.new(selected_ids: [ tomato.id ]).includes?(tomato.id)).to be true
    end

    it "is true for a staple when on, false when off" do
      expect(Pantry.new(selected_ids: [ tomato.id ], include_staples: true).includes?(salt.id)).to be true
      expect(Pantry.new(selected_ids: [ tomato.id ], include_staples: false).includes?(salt.id)).to be false
    end

    it "is false for an unrelated ingredient" do
      expect(Pantry.new(selected_ids: [ tomato.id ], include_staples: false).includes?(cheese.id)).to be false
    end
  end

  describe "#empty?" do
    it "is true when nothing is selected" do
      expect(Pantry.new(selected_ids: []).empty?).to be true
      expect(Pantry.new(selected_ids: nil).empty?).to be true
    end

    it "is false when ingredients are selected, regardless of staples" do
      expect(Pantry.new(selected_ids: [ tomato.id ], include_staples: false).empty?).to be false
    end
  end
end
