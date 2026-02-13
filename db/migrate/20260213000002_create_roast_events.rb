class CreateRoastEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :roast_events do |t|
      t.references :roast_session, null: false, foreign_key: true
      t.integer :time_seconds, null: false
      t.float :bean_temp_f
      t.float :manifold_wc
      t.integer :air_position, default: 2, null: false
      t.integer :event_type
      t.text :notes
      t.datetime :created_at, null: false
    end

    add_index :roast_events, [ :roast_session_id, :time_seconds ]
    add_index :roast_events, :event_type
  end
end
