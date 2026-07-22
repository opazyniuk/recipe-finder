# frozen_string_literal: true

class Ingredients::Parser::VarietyCollapser
  GROUPS = {
    "potato"   => %w[baking russet red yellow white gold golden purple new baby idaho fingerling boiling yukon creamer round waxy].to_set,
    "mushroom" => %w[button white cremini brown portobello bella baby].to_set,
    "tomato"   => %w[roma plum vine].to_set
  }.freeze

  def initialize(name)
    @name = name.to_s
  end

  def call
    collapse.presence
  end

  private

  def collapse
    tokens = @name.split
    return @name if tokens.size < 2

    varieties = GROUPS[tokens.last]
    return tokens.last if varieties && tokens[0..-2].all? { |token| varieties.include?(token) }

    @name
  end
end
