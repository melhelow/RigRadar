# app/models/truck_stop.rb
# == Schema Information
#
# Table name: truck_stops
#
#  id            :bigint           not null, primary key
#  city          :string
#  country       :string           default("US")
#  direction_url :text
#  latitude      :decimal(10, 6)
#  longitude     :decimal(10, 6)
#  name          :string           not null
#  opening_hours :string
#  parking_rv    :integer
#  parking_truck :integer
#  phone         :string
#  provider      :string
#  raw_details   :text
#  state         :string(2)
#  status        :string           default("active")
#  street        :string
#  website       :string
#  zip_code      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_truck_stops_on_latitude_and_longitude  (latitude,longitude)
#  index_truck_stops_on_name_lat_lon            (name,latitude,longitude) UNIQUE
#  index_truck_stops_on_provider                (provider)
#
class TruckStop < ApplicationRecord
   has_many :load_stops, as: :stoppable, dependent: :destroy, inverse_of: :stoppable
  has_many :loads, through: :load_stops
  validates :name, presence: true
  validates :latitude, :longitude, numericality: true, allow_nil: true

  scope :in_box, ->(min_lat, max_lat, min_lon, max_lon) {
  where(latitude: min_lat..max_lat, longitude: min_lon..max_lon)
}
scope :by_providers, ->(providers) {
  return all if providers.blank?
  where("LOWER(TRIM(provider)) IN (?)", Array(providers).map { _1.to_s.downcase.strip })
}
scope :min_parking, ->(n) {
  return all if n.blank?
  where("COALESCE(parking_truck, 0) >= ?", n.to_i)
}
end
