class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :title, null: false
      t.string :image_url
      t.string :category
      t.string :author
      t.integer :prep_time
      t.integer :cook_time
      t.integer :total_time
      t.float :ratings
      t.integer :ingredients_count, null: false, default: 0

      t.timestamps
    end
  end
end
