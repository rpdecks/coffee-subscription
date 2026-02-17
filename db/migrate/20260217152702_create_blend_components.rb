class CreateBlendComponents < ActiveRecord::Migration[8.1]
  def change
    create_table :blend_components do |t|
      t.references :product, null: false, foreign_key: true
      t.references :green_coffee, null: false, foreign_key: true
      t.decimal :percentage, precision: 5, scale: 2, null: false

      t.timestamps
    end

    add_index :blend_components, [ :product_id, :green_coffee_id ], unique: true
  end
end
