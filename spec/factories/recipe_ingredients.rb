FactoryBot.define do
  factory :recipe_ingredient do
    recipe
    ingredient
    raw_text { "1 cup flour" }
    quantity { nil }
    unit { nil }
    sequence(:position) { |n| n }
  end
end
