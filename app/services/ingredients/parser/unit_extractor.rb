# frozen_string_literal: true

class Ingredients::Parser::UnitExtractor
  def self.call(raw) = new(raw).call

  def initialize(raw)
    @raw = raw.to_s
  end

  def call
    @raw.gsub(/\([^)]*\)/, " ").downcase.split(/[^a-z]+/).each do |token|
      return token if Ingredients::Parser::UNITS.include?(token)
      return Ingredients::Parser::UNIT_PLURALS[token] if Ingredients::Parser::UNIT_PLURALS.key?(token)
    end
    nil
  end
end
