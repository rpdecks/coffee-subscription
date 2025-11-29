class CreateAddresses < ActiveRecord::Migration[7.2]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :address_type
      t.string :street_address
      t.string :street_address_2
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :country
      t.boolean :is_default

      t.timestamps
    end
  end
end
