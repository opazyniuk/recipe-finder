# frozen_string_literal: true

class Ingredients::Parser
  STAPLES = [
    "salt", "sea salt", "kosher salt", "table salt", "salt and pepper",
    "pepper", "black pepper", "white pepper",
    "water", "oil", "olive oil", "virgin olive oil",
    "vegetable oil", "canola oil", "cooking oil", "butter"
  ].to_set.freeze

  UNIT_WORDS = %w[
    teaspoon tablespoon cup ounce pound gram kilogram milligram milliliter liter
    pinch clove can package slice loaf stick quart pint gallon dash bunch sprig
    head jar bottle container box bag piece fluid
  ].freeze
  UNIT_ABBREVIATIONS = %w[tsp tbsp oz lb g kg mg ml l].freeze
  UNITS = (UNIT_WORDS + UNIT_ABBREVIATIONS).to_set.freeze
  UNIT_PLURALS = UNITS.index_by(&:pluralize).freeze
  UNIT_SURFACES = (UNITS + UNIT_PLURALS.keys).freeze

  def self.call(raw) = new(raw).call

  def self.staple?(name) = STAPLES.include?(name)

  def initialize(raw)
    @raw = raw
  end

  def call
    name = NameNormalizer.call(@raw)
    return nil if name.blank?

    Result.new(name: name, quantity: quantity, unit: unit)
  end

  private

  def quantity = QuantityExtractor.call(@raw)
  def unit = UnitExtractor.call(@raw)
end
