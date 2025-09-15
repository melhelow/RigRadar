
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
require "rails_helper"

RSpec.describe Load, type: :model do
  let(:driver) { Driver.create!(email: "driver@example.com", password: "password123") }

  it "is invalid without core fields" do
    load = described_class.new
    expect(load).not_to be_valid
    expect(load.errors[:commodity]).to be_present
    expect(load.errors[:pickup_location]).to be_present
    expect(load.errors[:dropoff_location]).to be_present
    expect(load.errors[:weight_lbs]).to be_present
  end

  it "requires positive integer weight_lbs" do
    load = described_class.new(
      driver: driver,
      commodity: "Steel",
      pickup_location: "Dallas, TX",
      dropoff_location: "Omaha, NE",
      weight_lbs: 0
    )
    expect(load).not_to be_valid

    load.weight_lbs = 40_000
    expect(load).to be_valid
  end
end
