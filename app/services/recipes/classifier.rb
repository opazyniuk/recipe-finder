# frozen_string_literal: true

class Recipes::Classifier
  MEAT = %w[
    beef pork chicken turkey lamb veal bacon ham sausage prosciutto pancetta
    pepperoni salami chorizo bratwurst meatball steak brisket rib ribs duck
    goose rabbit venison bison fish salmon tuna cod tilapia halibut trout
    sardine anchovy haddock mackerel shrimp prawn crab lobster clam mussel
    oyster scallop squid octopus crawfish gelatin lard suet tallow
  ].to_set.freeze

  DAIRY_EGG = %w[
    milk butter cheese cream yogurt yoghurt ghee buttermilk custard curd
    casein whey egg mayonnaise honey
  ].to_set.freeze

  PLANT = %w[
    coconut almond soy soya oat cashew peanut cocoa rice hemp sunflower
    macadamia walnut vegan nondairy plant
  ].to_set.freeze

  def initialize(name)
    @name = name
  end

  def meat? = tokens.any? { |token| MEAT.include?(token) }

  def animal?
    return true if meat?
    return false if tokens.any? { |token| PLANT.include?(token) }

    tokens.any? { |token| DAIRY_EGG.include?(token) }
  end

  private

  def tokens = @tokens ||= @name.to_s.downcase.scan(/[a-z]+/)
end
