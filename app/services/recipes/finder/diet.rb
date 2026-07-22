# frozen_string_literal: true

class Recipes::Finder
  module Diet
    FILTERS = {
      "vegetarian" => "r.is_vegetarian",
      "vegan"      => "r.is_vegan"
    }.freeze

    def self.filter_sql(value) = FILTERS[value.to_s]
  end
  private_constant :Diet
end
