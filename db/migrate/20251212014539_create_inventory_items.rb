class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :state, null: false, default: 0  # 0: green, 1: roasted, 2: packaged
      t.decimal :quantity, precision: 10, scale: 2, null: false, default: 0.0  # in pounds
      t.string :lot_number
      t.date :roasted_on
      t.date :received_on
      t.text :notes
      t.date :expires_on  # for tracking freshness

      t.timestamps
    end

    add_index :inventory_items, :state
    add_index :inventory_items, :roasted_on
    add_index :inventory_items, :received_on
  end
end
