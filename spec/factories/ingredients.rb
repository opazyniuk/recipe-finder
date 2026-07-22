FactoryBot.define do
  factory :ingredient do
    sequence(:name) { |n| "ingredient #{n}" }
    is_staple { false }
    recipes_count { 0 }

    trait :staple do
      is_staple { true }
    end
  end
end
