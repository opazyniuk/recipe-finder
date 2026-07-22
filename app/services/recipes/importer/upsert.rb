# frozen_string_literal: true

class Recipes::Importer
  class Upsert
    RECIPE_BATCH = 2_000
    JOIN_BATCH = 5_000

    def self.call(...) = new(...).call

    def initialize(parsed)
      @parsed = parsed
    end

    def call
      ApplicationRecord.transaction do
        ingredient_ids = upsert_ingredients(distinct_names)
        insert_recipes_with_links(ingredient_ids)
        recompute_counter_caches
        recompute_diet_flags
      end

      { recipes: Recipe.count, ingredients: Ingredient.count, links: RecipeIngredient.count }
    end

    private

    def distinct_names
      @parsed.each_with_object(Set.new) do |recipe, names|
        recipe.lines.each { |line| names << line[:name] }
      end
    end

    def upsert_ingredients(names)
      names.each_slice(JOIN_BATCH) do |batch|
        Ingredient.upsert_all(batch.map { |name| ingredient_row(name) }, unique_by: :name)
      end
      Ingredient.pluck(:name, :id).to_h
    end

    def ingredient_row(name)
      { name: name }.merge(Ingredients::Classification.for(name).to_h)
    end

    def insert_recipes_with_links(ingredient_ids)
      @parsed.each_slice(RECIPE_BATCH) do |batch|
        rows = batch.map(&:attributes)
        recipe_ids = Recipe.insert_all(rows, returning: %w[id]).rows.flatten
        links = build_links(batch, recipe_ids, ingredient_ids)
        links.each_slice(JOIN_BATCH) { |slice| RecipeIngredient.insert_all(slice) }
      end
    end

    def build_links(batch, recipe_ids, ingredient_ids)
      batch.each_with_index.flat_map do |recipe, i|
        recipe_id = recipe_ids[i]
        seen = Set.new
        recipe.lines.filter_map do |line|
          ingredient_id = ingredient_ids[line[:name]]
          next unless seen.add?(ingredient_id)

          {
            recipe_id: recipe_id,
            ingredient_id: ingredient_id,
            raw_text: line[:raw],
            quantity: line[:quantity],
            unit: line[:unit],
            position: line[:position]
          }
        end
      end
    end

    def recompute_counter_caches
      CounterCache.recompute_all_sql.each { |sql| connection.execute(sql) }
    end

    def recompute_diet_flags
      connection.execute(Recipes::Diet.recompute_all_sql)
    end

    def connection = ActiveRecord::Base.connection
  end
end
