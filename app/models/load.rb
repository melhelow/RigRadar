# == Schema Information
#
# Table name: loads
#
#  id               :bigint           not null, primary key
#  commodity        :string
#  deadline         :datetime
#  dropoff_lat      :decimal(10, 6)
#  dropoff_location :string
#  dropoff_lon      :decimal(10, 6)
#  pickup_lat       :decimal(10, 6)
#  pickup_location  :string
#  pickup_lon       :decimal(10, 6)
#  started_at       :datetime
#  status           :integer          default("planned"), not null
#  weight_lbs       :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  driver_id        :bigint           not null
#
# Indexes
#
#  index_loads_on_driver_id  (driver_id)
#
# Foreign Keys
#
#  fk_rails_...  (driver_id => drivers.id)
#
class Load < ApplicationRecord
  belongs_to :driver

  enum :status, {
    planned:     0,
    in_transit:  1,
    delivered:   2,
    dropped:     3
  }

  validates :commodity, :weight_lbs, :pickup_location, :dropoff_location, presence: true

  after_validation :geocode_pickup,  if: -> { will_save_change_to_attribute?(:pickup_location) }
  after_validation :geocode_dropoff, if: -> { will_save_change_to_attribute?(:dropoff_location) }

  private
  def geocode_pickup
    coords = Geocoder.search(pickup_location).first&.coordinates
    self.pickup_lat, self.pickup_lon = coords if coords
  end
  def geocode_dropoff
    coords = Geocoder.search(dropoff_location).first&.coordinates
    self.dropoff_lat, self.dropoff_lon = coords if coords
  end
end
