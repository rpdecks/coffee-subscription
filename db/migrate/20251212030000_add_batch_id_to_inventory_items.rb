class AddBatchIdToInventoryItems < ActiveRecord::Migration[8.1]
  def change
    add_column :inventory_items, :batch_id, :string
    add_index :inventory_items, :batch_id
  end
end
