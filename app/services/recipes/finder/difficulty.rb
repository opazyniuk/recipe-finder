# frozen_string_literal: true

class Recipes::Finder
  module Difficulty
    EASY = "r.total_time <= 30 AND r.ingredients_count <= 8"
    HARD = "r.total_time >= 75 OR r.ingredients_count >= 14"

    LABEL = "CASE WHEN #{EASY} THEN 'easy' WHEN #{HARD} THEN 'hard' ELSE 'medium' END"
    LEVELS = %w[easy medium hard].freeze

    def self.label_sql = LABEL

    def self.filter_sql(level)
      level = level.to_s
      "#{LABEL} = '#{level}'" if LEVELS.include?(level)
    end
  end
  private_constant :Difficulty
end
