class CreateIngredients < ActiveRecord::Migration[8.0]
  def change
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    create_table :ingredients do |t|
      t.string :name, null: false
      t.boolean :is_staple, null: false, default: false
      t.integer :recipes_count, null: false, default: 0

      t.timestamps
    end
    add_index :ingredients, :name, unique: true
    add_index :ingredients, :name, using: :gin, opclass: :gin_trgm_ops,
              name: "index_ingredients_on_name_trgm"
  end
end
