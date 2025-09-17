# == Schema Information
#
# Table name: weigh_stations
#
#  id         :bigint           not null, primary key
#  functional :string
#  lat        :decimal(10, 6)
#  lon        :decimal(10, 6)
#  name       :string
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  station_id :string
#
# Indexes
#
#  index_weigh_stations_on_lat_and_lon           (lat,lon)
#  index_weigh_stations_on_state_and_functional  (state,functional)
#
class WeighStation < ApplicationRecord
has_many :load_stops, as: :stoppable, dependent: :destroy, inverse_of: :stoppable
has_many :loads, through: :load_stops
validates :lat, :lon, numericality: true, allow_nil: true
scope :in_box, ->(min_lat, max_lat, min_lon, max_lon) {
  where(lat: min_lat..max_lat, lon: min_lon..max_lon)
}
end
