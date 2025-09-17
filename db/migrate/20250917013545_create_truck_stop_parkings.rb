class CreateTruckStopParkings < ActiveRecord::Migration[8.0]
  def change
    create_table :truck_stop_parkings do |t|
      t.string  :state_number
      t.string  :nhs_rest_stop
      t.string  :highway_route
      t.decimal :mile_post, precision: 10, scale: 3
      t.string  :municipality
      t.string  :county
      t.string  :state
      t.decimal :latitude,  precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.integer :number_of_spots
      t.decimal :x, precision: 12, scale: 6
      t.decimal :y, precision: 12, scale: 6
      t.timestamps
    end
    
    add_index :truck_stop_parkings, [:state, :county]
    add_index :truck_stop_parkings, [:latitude, :longitude]
  end
end
