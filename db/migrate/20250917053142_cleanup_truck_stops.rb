class CleanupTruckStops < ActiveRecord::Migration[7.1]
  def change
    remove_columns :truck_stops,
                   :country, :opening_hours, :parking_rv, :website,
                   :status, :raw_details, :direction_url,
                   if_exists: true
  end
end
