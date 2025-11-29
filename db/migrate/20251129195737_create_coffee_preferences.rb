class CreateCoffeePreferences < ActiveRecord::Migration[7.2]
  def change
    create_table :coffee_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :roast_level
      t.integer :grind_type
      t.text :flavor_notes
      t.text :special_instructions

      t.timestamps
    end
  end
end
