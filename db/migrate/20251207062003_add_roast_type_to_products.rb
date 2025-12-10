class AddRoastTypeToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :roast_type, :integer, default: 0
  end
end
