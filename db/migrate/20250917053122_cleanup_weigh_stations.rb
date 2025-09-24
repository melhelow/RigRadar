class CleanupWeighStations < ActiveRecord::Migration[7.1]
  def change
    remove_columns :weigh_stations,
                   :concat_id, :station_uid, :objectid, :fips_code,
                   :counts_year, :num_days_active, :sum_weight_year,
                   :x, :y, :latitude, :longitude,
                   if_exists: true
  end
end
