class MakeOrderSubscriptionIdOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :orders, :subscription_id, true
  end
end
