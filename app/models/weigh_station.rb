# == Schema Information
#
# Table name: weigh_stations
#
#  id              :integer          not null, primary key
#  counts_year     :integer
#  fips_code       :string
#  functional      :string
#  lat             :decimal(10, 6)
#  lon             :decimal(10, 6)
#  name            :string
#  num_days_active :integer
#  state           :string
#  station_uid     :string
#  sum_weight_year :bigint
#  x               :decimal(12, 6)
#  y               :decimal(12, 6)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  concat_id       :string
#
# Indexes
#
#  index_weigh_stations_on_lat_and_lon           (lat,lon)
#  index_weigh_stations_on_state_and_functional  (state,functional)
#  index_weigh_stations_on_station_uid           (station_uid) UNIQUE
#
class WeighStation < ApplicationRecord



end
