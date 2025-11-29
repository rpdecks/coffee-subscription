class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.integer :product_type
      t.integer :price_cents
      t.decimal :weight_oz
      t.integer :inventory_count
      t.boolean :active
      t.string :stripe_product_id
      t.string :stripe_price_id

      t.timestamps
    end
  end
end
