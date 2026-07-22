FactoryBot.define do
  factory :recipe do
    sequence(:title) { |n| "Recipe #{n}" }
    image_url { "https://example.com/image.jpg" }
    category { "Dinner" }
    author { "Test Chef" }
    prep_time { 10 }
    cook_time { 20 }
    total_time { 30 }
    ratings { 4.5 }
    ingredients_count { 0 }
  end
end
