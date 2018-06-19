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

ActiveRecord::Schema.define(version: 2018_06_19_145552) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "identities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "email"
    t.uuid "user_id"
    t.index ["email"], name: "index_identities_on_email"
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid"
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "service_config_params", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "uuid"
    t.string "environment"
    t.string "name"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "last_update_by_user_id"
    t.bigint "service_id"
    t.index ["service_id"], name: "index_service_config_params_on_service_id"
  end

  create_table "service_deployments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "commit_sha"
    t.string "environment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "created_by_user_id"
    t.bigint "service_id"
    t.index ["service_id"], name: "index_service_deployments_on_service_id"
  end

  create_table "service_permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "created_by_user_id"
    t.bigint "services_id"
    t.bigint "users_id"
    t.index ["services_id"], name: "index_service_permissions_on_services_id"
    t.index ["users_id"], name: "index_service_permissions_on_users_id"
  end

  create_table "service_status_checks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "environment_slug"
    t.integer "status"
    t.float "time_taken"
    t.string "url"
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "service_id"
    t.index ["service_id"], name: "index_service_status_checks_on_service_id"
  end

  create_table "services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "git_repo_url"
    t.uuid "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "identities", "users"
  add_foreign_key "service_deployments", "users", column: "created_by_user_id"
  add_foreign_key "service_permissions", "users", column: "created_by_user_id"
  add_foreign_key "service_status_checks", "services"
  add_foreign_key "services", "users", column: "created_by_user_id"
end
