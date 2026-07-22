# frozen_string_literal: true

module Recipes::Cuisine
  CUISINES = %w[
    Mexican Italian Asian Indian French Greek Chinese Japanese Thai Korean
    Irish German Spanish Mediterranean
  ].freeze

  def self.for(category)
    label = category.to_s.downcase
    CUISINES.find { |cuisine| label.include?("#{cuisine.downcase} recipes") }
  end
end
