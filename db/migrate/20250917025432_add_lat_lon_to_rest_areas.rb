class AddLatLonToRestAreas < ActiveRecord::Migration[7.1]
  def change
    # add columns only if missing
    add_column :rest_areas, :lat, :decimal, precision: 10, scale: 6 unless column_exists?(:rest_areas, :lat)
    add_column :rest_areas, :lon, :decimal, precision: 10, scale: 6 unless column_exists?(:rest_areas, :lon)

    # optional: ensure precision on existing columns
    if column_exists?(:rest_areas, :lat)
      change_column :rest_areas, :lat, :decimal, precision: 10, scale: 6
    end
    if column_exists?(:rest_areas, :lon)
      change_column :rest_areas, :lon, :decimal, precision: 10, scale: 6
    end

    add_index :rest_areas, [ :lat, :lon ] unless index_exists?(:rest_areas, [ :lat, :lon ])
  end
end
