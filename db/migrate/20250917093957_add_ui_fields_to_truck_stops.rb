class AddUiFieldsToTruckStops < ActiveRecord::Migration[8.0]
  def change
    add_column :truck_stops, :website,        :string unless column_exists?(:truck_stops, :website)
    add_column :truck_stops, :direction_url,  :string unless column_exists?(:truck_stops, :direction_url)
    add_column :truck_stops, :opening_hours,  :string unless column_exists?(:truck_stops, :opening_hours)
  end
end
