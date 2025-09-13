class CreateLoads < ActiveRecord::Migration[8.0]
  def change
    create_table :loads do |t|
      t.references :driver, null: false, foreign_key: true
      t.string :commodity
      t.integer :weight_lbs
      t.string :pickup_location
      t.string :dropoff_location
      t.decimal :pickup_lat, precision: 10, scale: 6
      t.decimal :pickup_lon, precision: 10, scale: 6
      t.decimal :dropoff_lat, precision: 10, scale: 6
      t.decimal :dropoff_lon, precision: 10, scale: 6
      t.datetime :deadline
      t.integer :status
      t.datetime :started_at

      t.timestamps
    end
  end
end
