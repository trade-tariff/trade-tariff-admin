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

ActiveRecord::Schema[8.0].define(version: 2026_02_12_150230) do
  create_table "sessions", force: :cascade do |t|
    t.string "token", null: false
    t.integer "user_id", null: false
    t.text "id_token", null: false
    t.datetime "expires_at"
    t.json "raw_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.string "email"
    t.integer "version"
    t.string "access_token"
    t.string "organisation_slug"
    t.string "organisation_content_id"
    t.boolean "disabled", default: false
    t.boolean "remotely_signed_out", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "entity"
    t.string "role", default: "GUEST", null: false
    t.index ["entity"], name: "index_users_on_entity"
  end

  add_foreign_key "sessions", "users"
end
