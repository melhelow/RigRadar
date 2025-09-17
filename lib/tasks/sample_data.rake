# lib/tasks/sample_data.rake
require "csv"

desc "Fill the database with sample data (POIs + demo loads). Run: `bin/rails sample_data` or `bundle exec rake sample_data`"
task sample_data: :environment do
  abort("Refusing to run in production.") if Rails.env.production?

  puts "== Preparing database =="
  Rake::Task["db:prepare"].invoke unless Rake::Task["db:prepare"].already_invoked

  # ---------------------------------------------------------------------------
  # CSV paths (fixed to your setup; can be overridden by env)
  rest_csv  = (ENV["REST_AREAS_CSV"].presence  || Rails.root.join("lib/csvs/NTAD_Truck_Stop_Parking.csv"))
  weigh_csv = (ENV["WEIGH_STATIONS_CSV"].presence || Rails.root.join("lib/csvs/NTAD_Weigh_in_Motion_Stations.csv"))
  ts_csv    = (ENV["TRUCK_STOPS_CSV"].presence || Rails.root.join("lib/csvs/truck_stops_verified.csv"))
  # ---------------------------------------------------------------------------

  def pick(h, *candidates)
    # tolerate different header spellings/cases
    candidates.each do |k|
      v = h[k] || h[k.to_s] || h[k.to_s.upcase] || h[k.to_s.downcase]
      return v if v.present?
    end
    nil
  end

  # ---------- Import Rest Areas (matches ERD) ----------
  if File.exist?(rest_csv)
    created = 0; updated = 0
    puts "== Importing Rest Areas from #{rest_csv} =="
    CSV.foreach(rest_csv, headers: true) do |row|
      h = row.to_h

      name          = pick(h, :name, :site_name, :sitename, :facility, :area_name)
      state         = pick(h, :state, :st, :province)
      highway_route = pick(h, :highway_route, :route, :highway, :hwy, :road)
      mile_post     = pick(h, :mile_post, :milepost, :mile, :mile_marker)
      lat           = pick(h, :lat, :latitude, :y)
      lon           = pick(h, :lon, :longitude, :x)
      spots         = pick(h, :number_of_spots, :truck_spaces, :truck_parking, :spaces, :parking)

      next if name.blank? || state.blank?

      ra = RestArea.find_or_initialize_by(
        name: name,
        state: state,
        highway_route: highway_route,
        mile_post: mile_post
      )

      ra.lat = lat.to_f if lat
      ra.lon = lon.to_f if lon
      ra.number_of_spots = spots.to_i if spots

      if ra.new_record?
        created += 1 if ra.save!
      else
        updated += 1 if ra.changed? && ra.save!
      end
    end
    puts "✅ Rest Areas: created=#{created}, updated=#{updated}"
  else
    puts "⚠️  Skipping rest areas (#{rest_csv} not found)"
  end

  # ---------- Import Weigh Stations (matches ERD) ----------
  if File.exist?(weigh_csv)
    created = 0; updated = 0
    puts "== Importing Weigh Stations from #{weigh_csv} =="
    CSV.foreach(weigh_csv, headers: true) do |row|
      h = row.to_h

      station_id = pick(h, :station_id, :stationid, :wim_id, :wimsiteid, :site_id, :siteid)
      name       = pick(h, :name, :site_name, :station_name)
      state      = pick(h, :state, :st, :province)
      lat        = pick(h, :lat, :latitude, :y)
      lon        = pick(h, :lon, :longitude, :x)
      functional = pick(h, :functional, :status, :operational)

      next if station_id.blank?

      ws = WeighStation.find_or_initialize_by(station_id: station_id)
      ws.name       = name
      ws.state      = state
      ws.lat        = lat.to_f if lat
      ws.lon        = lon.to_f if lon
      ws.functional = functional

      if ws.new_record?
        created += 1 if ws.save!
      else
        updated += 1 if ws.changed? && ws.save!
      end
    end
    puts "✅ Weigh Stations: created=#{created}, updated=#{updated}"
  else
    puts "⚠️  Skipping weigh stations (#{weigh_csv} not found)"
  end

  # ---------- Import Truck Stops (matches ERD) ----------
  if File.exist?(ts_csv)
    created = 0; updated = 0
    puts "== Importing Truck Stops from #{ts_csv} =="
    CSV.foreach(ts_csv, headers: true) do |row|
      h = row.to_h

      name          = pick(h, :name, :location_name, :stop_name)
      state         = pick(h, :state, :st)
      city          = pick(h, :city, :town)
      street        = pick(h, :street, :address, :address1)
      zip_code      = pick(h, :zip_code, :zipcode, :zip, :postal_code)
      phone         = pick(h, :phone, :phone_number)
      provider      = pick(h, :provider, :brand, :chain)
      latitude      = pick(h, :latitude, :lat, :y)
      longitude     = pick(h, :longitude, :lon, :long, :x)
      opening_hours = pick(h, :opening_hours, :hours, :open_hours)
      website       = pick(h, :website, :url)
      direction_url = pick(h, :direction_url, :directions_url, :google_maps_url, :maps_url)
      parking_truck = pick(h, :parking_truck, :truck_parking, :truck_spaces, :spaces)

      next if name.blank? || state.blank?

      # Natural key: name + state + city (+ street if present)
      key = { name: name, state: state, city: city }
      key[:street] = street if street.present?

      ts = TruckStop.find_or_initialize_by(key)
      ts.zip_code      = zip_code
      ts.phone         = phone
      ts.provider      = provider
      ts.latitude      = latitude.to_f if latitude
      ts.longitude     = longitude.to_f if longitude
      ts.opening_hours = opening_hours
      ts.website       = website
      ts.direction_url = direction_url
      ts.parking_truck = parking_truck.to_i if parking_truck

      if ts.new_record?
        created += 1 if ts.save!
      else
        updated += 1 if ts.changed? && ts.save!
      end
    end
    puts "✅ Truck Stops: created=#{created}, updated=#{updated}"
  else
    puts "⚠️  Skipping truck stops (#{ts_csv} not found)"
  end

  # ---------- Demo loads (Driver, Load, LoadStop) ----------
  puts "== Creating demo loads =="
  Rake::Task["sample:load"].reenable
  Rake::Task["sample:load"].invoke((ENV["LOAD_COUNT"] || 10).to_i, ENV["DEMO_EMAIL"] || "demo@example.com")

  puts "✅ Sample data ready."
end

# Optional alias so `db:sample_data` also works
namespace :db do
  task sample_data: :environment do
    Rake::Task["sample_data"].invoke
  end
end
