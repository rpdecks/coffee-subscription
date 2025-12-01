class AddBagSizeAndQuantityToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :subscriptions, :bag_size, :string
    add_column :subscriptions, :quantity, :integer
  end
end
