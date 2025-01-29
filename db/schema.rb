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

ActiveRecord::Schema[7.1].define(version: 2019_10_28_061635) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "import_tasks", force: :cascade do |t|
    t.integer "status", default: 0
    t.text "file_data"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.string "email"
    t.integer "version"
    t.text "permissions"
    t.string "access_token"
    t.string "organisation_slug"
    t.string "organisation_content_id"
    t.boolean "disabled", default: false
    t.boolean "remotely_signed_out", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

end
