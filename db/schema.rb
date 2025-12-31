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

ActiveRecord::Schema[8.1].define(version: 2025_12_31_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.integer "address_type"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.boolean "is_default"
    t.string "state"
    t.string "street_address"
    t.string "street_address_2"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "zip_code"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "coffee_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "flavor_notes"
    t.integer "grind_type"
    t.integer "roast_level"
    t.text "special_instructions"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_coffee_preferences_on_user_id"
  end

  create_table "inventory_items", force: :cascade do |t|
    t.string "batch_id"
    t.datetime "created_at", null: false
    t.date "expires_on"
    t.string "lot_number"
    t.text "notes"
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "0.0", null: false
    t.date "received_on"
    t.date "roasted_on"
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_inventory_items_on_batch_id"
    t.index ["product_id"], name: "index_inventory_items_on_product_id"
    t.index ["received_on"], name: "index_inventory_items_on_received_on"
    t.index ["roasted_on"], name: "index_inventory_items_on_roasted_on"
    t.index ["state"], name: "index_inventory_items_on_state"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "grind_type"
    t.bigint "order_id", null: false
    t.integer "price_cents"
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.text "special_instructions"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.string "order_number"
    t.integer "order_type"
    t.integer "payment_method_id"
    t.datetime "shipped_at"
    t.integer "shipping_address_id"
    t.integer "shipping_cents"
    t.integer "status"
    t.string "stripe_invoice_id"
    t.string "stripe_payment_intent_id"
    t.bigint "subscription_id", null: false
    t.integer "subtotal_cents"
    t.integer "tax_cents"
    t.integer "total_cents"
    t.string "tracking_number"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["subscription_id"], name: "index_orders_on_subscription_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string "card_brand"
    t.datetime "created_at", null: false
    t.integer "exp_month"
    t.integer "exp_year"
    t.boolean "is_default"
    t.string "last_four"
    t.string "stripe_payment_method_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_payment_methods_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "featured_image_attachment_id"
    t.bigint "image_attachment_ids_order", default: [], null: false, array: true
    t.integer "inventory_count"
    t.string "name"
    t.integer "price_cents"
    t.integer "product_type"
    t.integer "roast_type", default: 0
    t.string "stripe_price_id"
    t.string "stripe_product_id"
    t.datetime "updated_at", null: false
    t.boolean "visible_in_shop", default: true, null: false
    t.decimal "weight_oz"
    t.index ["featured_image_attachment_id"], name: "index_products_on_featured_image_attachment_id"
    t.index ["image_attachment_ids_order"], name: "index_products_on_image_attachment_ids_order", using: :gin
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.boolean "active"
    t.integer "bags_per_delivery"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "frequency"
    t.string "name"
    t.integer "price_cents"
    t.string "stripe_plan_id"
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "bag_size"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.integer "failed_payment_count", default: 0, null: false
    t.date "next_delivery_date"
    t.integer "payment_method_id"
    t.integer "quantity"
    t.integer "shipping_address_id"
    t.integer "status"
    t.string "stripe_subscription_id"
    t.bigint "subscription_plan_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["subscription_plan_id"], name: "index_subscriptions_on_subscription_plan_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.string "stripe_customer_id"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type"
    t.datetime "processed_at"
    t.string "stripe_event_id"
    t.datetime "updated_at", null: false
    t.index ["stripe_event_id"], name: "index_webhook_events_on_stripe_event_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "users"
  add_foreign_key "coffee_preferences", "users"
  add_foreign_key "inventory_items", "products"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "subscriptions"
  add_foreign_key "orders", "users"
  add_foreign_key "payment_methods", "users"
  add_foreign_key "subscriptions", "subscription_plans"
  add_foreign_key "subscriptions", "users"
end
