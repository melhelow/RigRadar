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
# app/models/load.rb
class Load < ApplicationRecord
  belongs_to :driver

  has_many :load_stops, dependent: :destroy
  has_many :rest_areas,     through: :load_stops, source: :stoppable, source_type: "RestArea"
  has_many :weigh_stations, through: :load_stops, source: :stoppable, source_type: "WeighStation"
  has_many :truck_stops,    through: :load_stops, source: :stoppable, source_type: "TruckStop"
  enum :status, { planned: 0, in_transit: 1, delivered: 2, dropped: 3 }

  validates :commodity, :weight_lbs, :pickup_location, :dropoff_location, presence: true

  after_validation :geocode_pickup,  if: -> { will_save_change_to_attribute?(:pickup_location) }
  after_validation :geocode_dropoff, if: -> { will_save_change_to_attribute?(:dropoff_location) }

  def regeocode!
    self.pickup_location_will_change!
    self.dropoff_location_will_change!
    save!
  end

  private

  def geocode_pickup
    if (coords = geocode_query(pickup_location))
      self.pickup_lat, self.pickup_lon = coords
    end
  end

  def geocode_dropoff
    if (coords = geocode_query(dropoff_location))
      self.dropoff_lat, self.dropoff_lon = coords
    end
  end

  def geocode_query(q)
    q = q.to_s.strip.gsub(/\s+/, " ")
    Geocoder.search(q).first&.coordinates ||
      Geocoder.search("#{q}, USA").first&.coordinates
  end
end
