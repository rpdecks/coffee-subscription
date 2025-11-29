class CreateSubscriptionPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :subscription_plans do |t|
      t.string :name
      t.text :description
      t.integer :frequency
      t.integer :bags_per_delivery
      t.integer :price_cents
      t.string :stripe_plan_id
      t.boolean :active

      t.timestamps
    end
  end
end
