class AddCuisineAndDietaryFacets < ActiveRecord::Migration[8.0]
  def change
    add_column :ingredients, :is_meat, :boolean, default: false, null: false
    add_column :ingredients, :is_animal, :boolean, default: false, null: false

    add_column :recipes, :cuisine, :string
    add_column :recipes, :is_vegetarian, :boolean, default: false, null: false
    add_column :recipes, :is_vegan, :boolean, default: false, null: false
    add_index :recipes, :cuisine
  end
end
