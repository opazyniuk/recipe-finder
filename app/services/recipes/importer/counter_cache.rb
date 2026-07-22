# frozen_string_literal: true

class Recipes::Importer
  module CounterCache
    def self.recompute_all_sql = [ recipes_sql, ingredients_sql ]

    def self.recipes_sql
      <<~SQL.squish
        UPDATE recipes SET ingredients_count = sub.cnt
        FROM (SELECT recipe_id, COUNT(*) AS cnt FROM recipe_ingredients GROUP BY recipe_id) sub
        WHERE recipes.id = sub.recipe_id
      SQL
    end

    def self.ingredients_sql
      <<~SQL.squish
        UPDATE ingredients SET recipes_count = sub.cnt
        FROM (SELECT ingredient_id, COUNT(*) AS cnt FROM recipe_ingredients GROUP BY ingredient_id) sub
        WHERE ingredients.id = sub.ingredient_id
      SQL
    end

    private_class_method :recipes_sql, :ingredients_sql
  end
end
