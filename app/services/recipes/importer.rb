# frozen_string_literal: true

class Recipes::Importer
  def self.call(**kwargs) = new(**kwargs).call

  def initialize(source: Dataset::DEFAULT_SOURCE, io: nil)
    @dataset = Dataset.new(source: source, io: io)
  end

  def call
    return :already_seeded if seeded?

    parsed_recipes = parse_recipes

    upsert_results = Upsert.call(parsed_recipes)

    build_result(parsed_recipes, upsert_results)
  end

  private

  attr_reader :dataset

  def build_result(parsed_recipes, counts)
    kept = clean_lines(parsed_recipes)

    Result.new(**counts, dropped_lines: raw_lines - kept)
  end

  def raw_recipes = @raw_recipes ||= dataset.records

  def parse_recipes
    raw_recipes.map do |record|
      ParsedRecipe.from(record)
    end
  end

  def raw_lines
    raw_recipes.sum { |record| Array(record["ingredients"]).size }
  end

  def clean_lines(parsed_recipes)
    parsed_recipes.sum { |recipe| recipe.lines.size }
  end

  def seeded? = Recipe.exists?
end
