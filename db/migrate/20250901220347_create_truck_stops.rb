class CreateTruckStops < ActiveRecord::Migration[8.0]
  def change
    create_table :truck_stops do |t|
      t.string  :name,    null: false
      t.string  :provider
      t.string  :website
      t.string  :phone
      t.string  :opening_hours

      t.string  :street
      t.string  :city
      t.string  :state, limit: 2
      t.string  :zip_code
      t.string  :country, default: "US"
      t.string  :status,  default: "active"

      t.text    :direction_url
      t.decimal :latitude,  precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6

      t.integer :parking_truck
      t.integer :parking_rv
      t.text    :raw_details

      t.timestamps
    end

    add_index :truck_stops, [:latitude, :longitude]
    add_index :truck_stops, [:name, :latitude, :longitude], unique: true, name: "index_truck_stops_on_name_lat_lon"
    add_index :truck_stops, :provider
  end
end
