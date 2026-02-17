class CreateGreenCoffees < ActiveRecord::Migration[8.1]
  def change
    create_table :green_coffees do |t|
      t.references :supplier, null: false, foreign_key: true
      t.string :name
      t.string :origin_country
      t.string :region
      t.string :variety
      t.string :process
      t.date :harvest_date
      t.date :arrived_on
      t.decimal :cost_per_lb, precision: 8, scale: 2
      t.decimal :quantity_lbs, precision: 10, scale: 2, null: false, default: 0.0
      t.string :lot_number
      t.text :notes

      t.timestamps
    end
  end
end
