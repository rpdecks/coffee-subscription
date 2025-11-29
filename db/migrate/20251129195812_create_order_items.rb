class CreateOrderItems < ActiveRecord::Migration[7.2]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.integer :price_cents
      t.integer :grind_type
      t.text :special_instructions

      t.timestamps
    end
  end
end
