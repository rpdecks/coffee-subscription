class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subscription, null: false, foreign_key: true
      t.string :order_number
      t.integer :order_type
      t.integer :status
      t.integer :subtotal_cents
      t.integer :shipping_cents
      t.integer :tax_cents
      t.integer :total_cents
      t.string :stripe_payment_intent_id
      t.integer :shipping_address_id
      t.integer :payment_method_id
      t.datetime :shipped_at
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
