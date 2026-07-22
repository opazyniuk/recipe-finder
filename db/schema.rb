# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_06_21_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "ingredients", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "is_staple", default: false, null: false
    t.integer "recipes_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_meat", default: false, null: false
    t.boolean "is_animal", default: false, null: false
    t.index ["name"], name: "index_ingredients_on_name", unique: true
    t.index ["name"], name: "index_ingredients_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "ingredient_id", null: false
    t.string "raw_text", null: false
    t.decimal "quantity"
    t.string "unit"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["recipe_id", "ingredient_id"], name: "index_recipe_ingredients_on_recipe_id_and_ingredient_id", unique: true
  end

  create_table "recipes", force: :cascade do |t|
    t.string "title", null: false
    t.string "image_url"
    t.string "category"
    t.string "author"
    t.integer "prep_time"
    t.integer "cook_time"
    t.integer "total_time"
    t.float "ratings"
    t.integer "ingredients_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cuisine"
    t.boolean "is_vegetarian", default: false, null: false
    t.boolean "is_vegan", default: false, null: false
    t.index ["cuisine"], name: "index_recipes_on_cuisine"
  end

  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_ingredients", "recipes"
end
