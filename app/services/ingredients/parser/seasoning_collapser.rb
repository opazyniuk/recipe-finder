# frozen_string_literal: true

class Ingredients::Parser::SeasoningCollapser
  WORDS = %w[salt pepper black white sea kosher table coarse cracked fine ground and].to_set.freeze

  def initialize(name)
    @name = name.to_s
  end

  def call
    tokens = @name.split
    return @name unless tokens.include?("salt") && tokens.include?("pepper")
    return "salt and pepper" if tokens.all? { |token| WORDS.include?(token) }

    @name
  end
end
