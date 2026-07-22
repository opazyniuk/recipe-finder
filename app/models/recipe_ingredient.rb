class RecipeIngredient < ApplicationRecord
  belongs_to :recipe, counter_cache: :ingredients_count
  belongs_to :ingredient, counter_cache: :recipes_count

  validates :raw_text, presence: true
  validates :ingredient_id, uniqueness: { scope: :recipe_id }
end
