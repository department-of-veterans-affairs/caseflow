# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161102170128) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appeals", force: :cascade do |t|
    t.string "vacols_id", null: false
    t.string "vbms_id"
  end

  add_index "appeals", ["vacols_id"], name: "index_appeals_on_vacols_id", unique: true, using: :btree

  create_table "certifications", force: :cascade do |t|
    t.string   "vacols_id"
    t.boolean  "already_certified"
    t.boolean  "vacols_data_missing"
    t.datetime "nod_matching_at"
    t.datetime "soc_matching_at"
    t.datetime "form9_matching_at"
    t.boolean  "ssocs_required"
    t.datetime "ssocs_matching_at"
    t.datetime "form8_started_at"
    t.datetime "completed_at"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.integer  "appeal_id",         null: false
    t.string   "type",              null: false
    t.integer  "user_id"
    t.datetime "assigned_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer  "completion_status"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "tasks", ["appeal_id", "type"], name: "index_tasks_on_appeal_id_and_type", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string "station_id", null: false
    t.string "css_id",     null: false
  end

  add_index "users", ["station_id", "css_id"], name: "index_users_on_station_id_and_css_id", unique: true, using: :btree

end
