class AddIndexesToRestAreasAndWeighStations < ActiveRecord::Migration[8.0]
  def change
    add_index :rest_areas, :object_uid, unique: true unless index_exists?(:rest_areas, :object_uid)
    add_index :rest_areas, [ :state, :highway_route, :mile_post ] unless index_exists?(:rest_areas, [ :state, :highway_route, :mile_post ])
    add_index :rest_areas, [ :lat, :lon ] unless index_exists?(:rest_areas, [ :lat, :lon ])

    # WeighStations
    add_index :weigh_stations, :station_uid, unique: true unless index_exists?(:weigh_stations, :station_uid)
    add_index :weigh_stations, [ :state, :functional ] unless index_exists?(:weigh_stations, [ :state, :functional ])
    add_index :weigh_stations, [ :lat, :lon ] unless index_exists?(:weigh_stations, [ :lat, :lon ])
  end
end
