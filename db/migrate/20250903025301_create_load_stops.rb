class CreateLoadStops < ActiveRecord::Migration[8.0]
  def change
    create_table :load_stops do |t|
      t.references :load, null: false, foreign_key: true
      t.references :stoppable, polymorphic: true, null: false
      t.integer :position

      t.timestamps
    end
     add_index :load_stops, [ :load_id, :stoppable_type, :stoppable_id ],
              unique: true, name: "idx_unique_load_stoppable"
  end
end
