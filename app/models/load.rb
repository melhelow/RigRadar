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
#  status           :integer
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
end
