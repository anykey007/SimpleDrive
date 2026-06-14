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

ActiveRecord::Schema[8.1].define(version: 2026_06_14_001000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "blobs", force: :cascade do |t|
    t.string "checksum_sha256", null: false
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.bigint "size_bytes", null: false
    t.string "storage_key", null: false
    t.bigint "storage_provider_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["storage_key"], name: "index_blobs_on_storage_key", unique: true
    t.index ["storage_provider_id"], name: "index_blobs_on_storage_provider_id"
    t.index ["user_id", "external_id"], name: "index_blobs_on_user_id_and_external_id", unique: true
    t.index ["user_id"], name: "index_blobs_on_user_id"
  end

  create_table "storage_providers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "adapter_type", null: false
    t.jsonb "configuration", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "name"], name: "index_storage_providers_on_tenant_id_and_name", unique: true
    t.index ["tenant_id"], name: "index_storage_providers_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "email"], name: "index_users_on_tenant_id_and_email", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  add_foreign_key "api_tokens", "users"
  add_foreign_key "blobs", "storage_providers"
  add_foreign_key "blobs", "users"
  add_foreign_key "storage_providers", "tenants"
  add_foreign_key "users", "tenants"
end
