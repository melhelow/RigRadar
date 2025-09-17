
# == Schema Information
#
# Table name: truck_stops
#
#  id            :bigint           not null, primary key
#  city          :string
#  direction_url :string
#  latitude      :decimal(10, 6)
#  longitude     :decimal(10, 6)
#  name          :string           not null
#  opening_hours :string
#  parking_truck :integer
#  phone         :string
#  provider      :string
#  state         :string(2)
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
require "rails_helper"

RSpec.describe TruckStop, type: :model do
  it "requires name" do
    ts = described_class.new
    expect(ts).not_to be_valid
    expect(ts.errors[:name]).to be_present
  end
end
