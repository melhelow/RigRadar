# == Schema Information
#
# Table name: rest_areas
#
#  id              :bigint           not null, primary key
#  county          :string
#  highway_route   :string
#  lat             :decimal(10, 6)
#  lon             :decimal(10, 6)
#  mile_post       :decimal(10, 2)
#  municipality    :string
#  name            :string
#  nhs_rest_stop   :string
#  number_of_spots :integer
#  object_uid      :string
#  state           :string
#  state_number    :string
#  x               :decimal(12, 6)
#  y               :decimal(12, 6)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_rest_areas_on_lat_and_lon                            (lat,lon)
#  index_rest_areas_on_object_uid                             (object_uid) UNIQUE
#  index_rest_areas_on_state_and_highway_route_and_mile_post  (state,highway_route,mile_post)
#
class RestArea < ApplicationRecord
has_many :load_stops, as: :stoppable, dependent: :destroy, inverse_of: :stoppable
  has_many :loads, through: :load_stops
end
