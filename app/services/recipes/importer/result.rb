# frozen_string_literal: true

class Recipes::Importer
  Result = Data.define(:recipes, :ingredients, :links, :dropped_lines)
end
