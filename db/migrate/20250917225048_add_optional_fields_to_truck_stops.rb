# db/migrate/20250917225048_add_optional_fields_to_truck_stops.rb
class AddOptionalFieldsToTruckStops < ActiveRecord::Migration[8.0]
  def change
    add_column :truck_stops, :direction_url, :string unless column_exists?(:truck_stops, :direction_url)
    # NOTE: per your request, we are NOT adding :website or :opening_hours
  end
end
