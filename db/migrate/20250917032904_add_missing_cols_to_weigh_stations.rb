class AddMissingColsToWeighStations < ActiveRecord::Migration[8.0]
  def change
    add_column :weigh_stations, :station_id, :string  unless column_exists?(:weigh_stations, :station_id)
    add_column :weigh_stations, :objectid,   :bigint  unless column_exists?(:weigh_stations, :objectid)

    add_column :weigh_stations, :latitude,  :decimal, precision: 10, scale: 6 unless column_exists?(:weigh_stations, :latitude)
    add_column :weigh_stations, :longitude, :decimal, precision: 10, scale: 6 unless column_exists?(:weigh_stations, :longitude)

    add_column :weigh_stations, :lat, :decimal, precision: 10, scale: 6 unless column_exists?(:weigh_stations, :lat)
    add_column :weigh_stations, :lon, :decimal, precision: 10, scale: 6 unless column_exists?(:weigh_stations, :lon)

    add_column :weigh_stations, :name, :string unless column_exists?(:weigh_stations, :name)

    add_index  :weigh_stations, [:lat, :lon] unless index_exists?(:weigh_stations, [:lat, :lon])
  end
end
