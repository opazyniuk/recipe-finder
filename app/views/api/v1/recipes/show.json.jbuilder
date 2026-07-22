json.extract! @recipe, :id, :title, :image_url, :prep_time, :cook_time, :total_time, :ratings, :category, :cuisine, :author

json.ingredients @recipe.recipe_ingredients.sort_by { |ri| ri.position || 0 } do |ri|
  json.name      ri.ingredient.name
  json.raw_text  ri.raw_text
  json.is_staple ri.ingredient.is_staple
  json.is_available @pantry.includes?(ri.ingredient_id)
end
