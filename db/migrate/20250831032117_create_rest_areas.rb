class CreateRestAreas < ActiveRecord::Migration[8.0]
  def change
    create_table :rest_areas do |t|
      t.string :object_uid
      t.string :state_number
      t.string :nhs_rest_stop
      t.string :highway_route
      t.decimal :mile_post, precision: 10, scale: 2
      t.string :municipality
      t.string :county
      t.string :state
      t.decimal :lat, precision: 10, scale: 6
      t.decimal :lon, precision: 10, scale: 6
      t.integer :number_of_spots
      t.decimal :x, precision: 12, scale: 6
      t.decimal :y, precision: 12, scale: 6
      t.string :name

      t.timestamps
    end
  end
end
