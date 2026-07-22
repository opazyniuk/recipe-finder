# frozen_string_literal: true

class Ingredients::Search
  LIMIT = 10
  POPULAR_LIMIT = 12
  NON_ALPHABET = /[^a-z ]+/

  def self.autocomplete(query)
    new(query).autocomplete
  end

  def self.popular
    Ingredient.where(is_staple: false).order(recipes_count: :desc).limit(POPULAR_LIMIT)
  end

  def initialize(raw_query)
    @raw_query = raw_query
  end

  def autocomplete
    query = normalize
    return Ingredient.none if query.blank?

    prefix = "#{query}%"
    Ingredient
      .where("name ILIKE :prefix OR name % :query", prefix: prefix, query: query)
      .order(prefix_first(prefix), recipes_count: :desc, name: :asc)
      .limit(LIMIT)
  end

  private

  def normalize
    I18n.transliterate(@raw_query.to_s).downcase.gsub(NON_ALPHABET, " ").squeeze(" ").strip
  end

  def prefix_first(prefix)
    Arel.sql(Ingredient.sanitize_sql_array([ "(name ILIKE ?) DESC", prefix ]))
  end
end
