class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.string :url
      t.string :contact_name
      t.string :contact_email
      t.text :notes

      t.timestamps
    end
  end
end
