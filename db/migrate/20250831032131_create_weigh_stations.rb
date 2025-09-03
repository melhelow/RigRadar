class CreateWeighStations < ActiveRecord::Migration[8.0]
  def change
    create_table :weigh_stations do |t|
      t.string :station_uid
      t.string :concat_id
      t.string :fips_code
      t.string :state
      t.string :functional
      t.decimal :lat, precision: 10, scale: 6
      t.decimal :lon, precision: 10, scale: 6
      t.integer :counts_year
      t.bigint :sum_weight_year
      t.integer :num_days_active
      t.decimal :x, precision: 12, scale: 6
      t.decimal :y, precision: 12, scale: 6
      t.string :name

      t.timestamps
    end
  end
end
