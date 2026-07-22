# frozen_string_literal: true

class Pantry
  attr_reader :selected_ids

  def initialize(selected_ids:, include_staples: true)
    @selected_ids = Array(selected_ids).map(&:to_i).uniq
    @include_staples = ActiveModel::Type::Boolean.new.cast(include_staples)
  end

  def available_ids
    @available_ids ||=
      @include_staples ? (@selected_ids + Ingredient.staples.pluck(:id)).uniq : @selected_ids
  end

  def includes?(ingredient_id) = available_set.include?(ingredient_id)

  def empty? = @selected_ids.empty?

  private

  def available_set = @available_set ||= available_ids.to_set
end
