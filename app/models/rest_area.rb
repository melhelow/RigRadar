# == Schema Information
#
# Table name: rest_areas
#
#  id              :bigint           not null, primary key
#  highway_route   :string
#  lat             :decimal(10, 6)
#  lon             :decimal(10, 6)
#  mile_post       :decimal(10, 2)
#  name            :string
#  number_of_spots :integer
#  state           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_rest_areas_on_lat_and_lon                            (lat,lon)
#  index_rest_areas_on_state_and_highway_route_and_mile_post  (state,highway_route,mile_post)
#
class RestArea < ApplicationRecord
has_many :load_stops, as: :stoppable, dependent: :destroy, inverse_of: :stoppable
has_many :loads, through: :load_stops
validates :lat, :lon, numericality: true, allow_nil: true
scope :in_box, ->(min_lat, max_lat, min_lon, max_lon) {
  where(lat: min_lat..max_lat, lon: min_lon..max_lon)
}
end
