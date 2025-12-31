class AddImageAttachmentIdsOrderToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :image_attachment_ids_order, :bigint, array: true, default: [], null: false
    add_index :products, :image_attachment_ids_order, using: :gin
  end
end
