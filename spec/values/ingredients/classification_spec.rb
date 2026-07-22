require 'rails_helper'

RSpec.describe Ingredients::Classification do
  it "classifies a name into staple / meat / animal flags" do
    expect(described_class.for("salt")).to have_attributes(is_staple: true, is_meat: false, is_animal: false)
    expect(described_class.for("chicken breast")).to have_attributes(is_staple: false, is_meat: true, is_animal: true)
    expect(described_class.for("egg")).to have_attributes(is_staple: false, is_meat: false, is_animal: true)
    expect(described_class.for("onion")).to have_attributes(is_staple: false, is_meat: false, is_animal: false)
  end

  it "exposes a hash for bulk upsert rows" do
    expect(described_class.for("butter").to_h).to eq(is_staple: true, is_meat: false, is_animal: true)
  end
end
