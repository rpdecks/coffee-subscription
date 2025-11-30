class AddTrackingNumberToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :tracking_number, :string
  end
end
