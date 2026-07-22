# frozen_string_literal: true

class Recipes::UkrainianSeeder
  CUISINE = "Ukrainian"
  TOP_RATING = 5.0

  def self.call(records) = new(records).call

  def initialize(records)
    @records = records
  end

  def call
    @records.each { |data| upsert_recipe(data) }
  end

  private

  def upsert_recipe(data)
    recipe = Recipe.find_or_initialize_by(title: data[:title])
    recipe.assign_attributes(
      category: data[:category], author: "Ukrainian Kitchen", cuisine: CUISINE,
      image_url: data[:image_url], prep_time: data[:prep_time], cook_time: data[:cook_time],
      total_time: data[:prep_time].to_i + data[:cook_time].to_i, ratings: TOP_RATING
    )
    return recipe.save! unless recipe.new_record?

    ApplicationRecord.transaction do
      recipe.save!
      link_ingredients(recipe, data[:ingredients])
      recipe.update!(Recipes::Diet.flags_for(recipe.ingredients))
    end
  end

  def link_ingredients(recipe, lines)
    seen = Set.new
    lines.each_with_index do |raw, position|
      next unless (parsed = Ingredients::Parser.call(raw))

      ingredient = find_or_create_ingredient(parsed.name)
      next unless seen.add?(ingredient.id)

      RecipeIngredient.create!(
        recipe: recipe, ingredient: ingredient, raw_text: raw,
        quantity: parsed.quantity, unit: parsed.unit, position: position
      )
    end
  end

  def find_or_create_ingredient(name)
    Ingredient.find_or_create_by!(name: name) do |ingredient|
      ingredient.assign_attributes(Ingredients::Classification.for(name).to_h)
    end
  end
end
