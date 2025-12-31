class AddFeaturedImageAttachmentIdToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :featured_image_attachment_id, :bigint
    add_index :products, :featured_image_attachment_id
  end
end
