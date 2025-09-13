class AddUniqueIndexToLoadStops < ActiveRecord::Migration[8.0]
  def change
    add_index :load_stops, [ :load_id, :stoppable_type, :stoppable_id ],
              unique: true, name: "index_load_stops_on_load_and_stoppable"
  end
end
