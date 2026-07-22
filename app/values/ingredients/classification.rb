# frozen_string_literal: true

Ingredients::Classification = Data.define(:is_staple, :is_meat, :is_animal) do
  def self.for(name)
    diet = Recipes::Classifier.new(name)
    new(is_staple: Ingredients::Parser.staple?(name), is_meat: diet.meat?, is_animal: diet.animal?)
  end
end
