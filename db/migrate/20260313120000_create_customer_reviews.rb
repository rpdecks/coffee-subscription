class CreateCustomerReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_reviews do |t|
      t.references :product, null: true, foreign_key: true
      t.string :customer_name, null: false
      t.string :location
      t.string :headline
      t.text :body, null: false
      t.integer :rating, null: false, default: 5
      t.boolean :approved, null: false, default: false
      t.boolean :featured_on_about, null: false, default: false
      t.integer :sort_position, null: false, default: 0

      t.timestamps
    end

    add_index :customer_reviews, [ :product_id, :approved, :created_at ]
    add_index :customer_reviews, [ :approved, :featured_on_about, :sort_position ], name: "index_customer_reviews_on_about_display"
  end
end