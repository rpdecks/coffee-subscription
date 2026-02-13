class CreateRoastSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :roast_sessions do |t|
      t.string :coffee_name, null: false
      t.string :lot_id
      t.string :process
      t.integer :batch_size_g, null: false
      t.float :ambient_temp_f
      t.float :charge_temp_target_f
      t.integer :gas_type, default: 0, null: false
      t.integer :green_weight_g
      t.integer :roasted_weight_g
      t.datetime :started_at
      t.datetime :ended_at
      t.text :notes
      # Derived metrics (calculated on DROP)
      t.integer :total_roast_time_seconds
      t.integer :development_time_seconds
      t.float :development_ratio
      t.float :weight_loss_percent
      t.timestamps
    end

    add_index :roast_sessions, :started_at
    add_index :roast_sessions, :coffee_name
  end
end
