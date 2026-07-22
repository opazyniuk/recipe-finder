# frozen_string_literal: true

module Recipes::Diet
  PREDICATES = { is_vegetarian: :is_meat, is_vegan: :is_animal }.freeze

  def self.flags_for(ingredients)
    PREDICATES.transform_values { |ingredient_flag| ingredients.none? { |ingredient| ingredient.public_send(ingredient_flag) } }
  end

  def self.recompute_all_sql
    assignments = PREDICATES.map do |diet_flag, ingredient_flag|
      "#{diet_flag} = NOT EXISTS (SELECT 1 FROM recipe_ingredients ri " \
        "JOIN ingredients i ON i.id = ri.ingredient_id WHERE ri.recipe_id = r.id AND i.#{ingredient_flag})"
    end.join(", ")
    "UPDATE recipes r SET #{assignments}"
  end
end
