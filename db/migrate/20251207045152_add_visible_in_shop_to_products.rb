class AddVisibleInShopToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :visible_in_shop, :boolean, default: true, null: false
  end
end
