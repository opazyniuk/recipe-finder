result = Recipes::Importer.call
if result == :already_seeded
  puts "Recipes already seeded (#{Recipe.count} recipes) — skipping import."
else
  puts "Seeded #{result.recipes} recipes, #{result.ingredients} ingredients, #{result.links} links (#{result.dropped_lines} dropped)."
end

records = eval(Rails.root.join("db/seeds/ukrainian_recipes.rb").read, binding, "db/seeds/ukrainian_recipes.rb")
Recipes::UkrainianSeeder.call(records)
puts "Ukrainian recipes: #{records.size} seeded."
