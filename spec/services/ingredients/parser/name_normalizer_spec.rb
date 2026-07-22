require 'rails_helper'

RSpec.describe Ingredients::Parser::NameNormalizer do
  describe ".call → canonical name (real dataset lines)" do
    {
      "1 cup all-purpose flour"                     => "all purpose flour",
      "1 cup yellow cornmeal"                       => "yellow cornmeal",
      "⅔ cup white sugar"                           => "white sugar",
      "1 teaspoon salt"                             => "salt",
      "3 ½ teaspoons baking powder"                 => "baking powder",
      "1 egg"                                       => "egg",
      "⅓ cup vegetable oil"                         => "vegetable oil",
      "1 (8 ounce) package cream cheese, softened"  => "cream cheese",
      "1 (2 1/2 pound) boneless pork loin roast"    => "pork loin roast",
      "2 lemons, sliced"                            => "lemon",
      "4 cloves garlic, chopped"                    => "garlic",
      "1 cup chopped fresh spinach"                 => "spinach",
      "8 ounces shredded Cheddar cheese"            => "cheddar cheese",
      "1 loaf sliced white bread"                   => "white bread",
      "2 apples (such as Gala or Pink Lady), diced" => "apple",
      "1 small clove garlic, minced"                => "garlic",
      "½ cup rice wine vinegar"                     => "rice wine vinegar",
      "salt and black pepper to taste"              => "salt and pepper",
      "4 skinless, boneless chicken breast halves"  => "chicken breast halve",
      "2 pounds boneless, skinless chicken thighs"  => "chicken thigh",
      "1 cup flour, sifted, plus more for dusting"  => "flour",
      "2 tablespoons fresh cilantro, for garnish"   => "cilantro",
      "1 pound chicken breast, cut into 1-inch pieces" => "chicken breast"
    }.each do |input, expected|
      it "#{input.inspect} → #{expected.inspect}" do
        expect(Ingredients::Parser::NameNormalizer.call(input)).to eq(expected)
      end
    end
  end

  describe ".call → variety collapse (so a pantry 'potato' matches 'baking potato')" do
    {
      "2 large baking potatoes"          => "potato",
      "3 russet potatoes, peeled"        => "potato",
      "4 Yukon Gold potatoes"            => "potato",
      "1 pound baby red potatoes"        => "potato",
      "8 ounces white mushrooms, sliced" => "mushroom",
      "1 cup cremini mushrooms"          => "mushroom",
      "3 roma tomatoes"                  => "tomato",
      "2 sweet potatoes, cubed"          => "sweet potato",
      "1 bag potato chips"               => "potato chip",
      "1 loaf potato bread"              => "potato bread",
      "1 white onion, diced"             => "white onion",
      "4 portobello mushroom caps"       => "portobello mushroom cap",
      "1 cup cherry tomatoes"            => "cherry tomato"
    }.each do |input, expected|
      it "#{input.inspect} → #{expected.inspect}" do
        expect(Ingredients::Parser::NameNormalizer.call(input)).to eq(expected)
      end
    end
  end

  describe ".call → dedup: drops alternatives / accompaniments / dangling connectives" do
    {
      "1 cup chicken broth or water"                       => "chicken broth",
      "1 (14.5 ounce) can diced tomatoes, undrained"       => "tomato",
      "1 onion, cut in half"                               => "onion",
      "2 tablespoons tomato paste with basil"              => "tomato paste",
      "1 (14.5 ounce) can diced tomatoes and green chiles" => "tomato and green chile"
    }.each do |input, expected|
      it "#{input.inspect} → #{expected.inspect}" do
        expect(Ingredients::Parser::NameNormalizer.call(input)).to eq(expected)
      end
    end
  end

  describe ".call → accent folding + precise seasoning collapse" do
    {
      "1 jalapeño pepper, seeded and minced"        => "jalapeno pepper",
      "2 tablespoons crème fraîche"                 => "creme fraiche",
      "kosher salt and freshly ground black pepper" => "salt and pepper",
      "1 pound salt and pepper shrimp"              => "salt and pepper shrimp"
    }.each do |input, expected|
      it "#{input.inspect} → #{expected.inspect}" do
        expect(Ingredients::Parser::NameNormalizer.call(input)).to eq(expected)
      end
    end
  end
end
