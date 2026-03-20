class AddDeliveryNoteToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :delivery_note, :text
  end
end
