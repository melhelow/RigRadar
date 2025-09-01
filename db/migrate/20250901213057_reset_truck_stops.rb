class ResetTruckStops < ActiveRecord::Migration[7.1]
  def change
    drop_table :truck_stops, if_exists: true
  end
end
