class CreatePaymentMethods < ActiveRecord::Migration[7.2]
  def change
    create_table :payment_methods do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_payment_method_id
      t.string :card_brand
      t.string :last_four
      t.integer :exp_month
      t.integer :exp_year
      t.boolean :is_default

      t.timestamps
    end
  end
end
