# lib/tasks/sample.rake
namespace :sample do
  desc "Generate demo loads (and attach nearby stops). Usage: bin/rails 'sample:load[COUNT,EMAIL]'"
  task :load, [:count, :email] => :environment do |_, args|
    abort("Refusing to run in production.") if Rails.env.production?

    begin
      require "faker"
    rescue LoadError
      # ok if Faker not installed; we'll use simple values
    end

    count = (args[:count] || 15).to_i
    email = (args[:email] || "demo@example.com").to_s

    driver = Driver.find_or_create_by!(email: email) do |d|
      d.password = "password123"
      d.name = "Demo Driver"
    end

    # A few fixed city pairs with coordinates so we don't depend on geocoder calls.
    city_pairs = [
      { pickup: { name: "Dallas, TX",     lat: 32.7767, lon: -96.7970 },
        dropoff:{ name: "Davenport, IA",  lat: 41.5236, lon: -90.5776 } },
      { pickup: { name: "Chicago, IL",    lat: 41.8781, lon: -87.6298 },
        dropoff:{ name: "Omaha, NE",      lat: 41.2565, lon: -95.9345 } },
      { pickup: { name: "Memphis, TN",    lat: 35.1495, lon: -90.0490 },
        dropoff:{ name: "Indianapolis, IN",lat: 39.7684, lon: -86.1581 } },
      { pickup: { name: "Atlanta, GA",    lat: 33.7490, lon: -84.3880 },
        dropoff:{ name: "Nashville, TN",  lat: 36.1627, lon: -86.7816 } },
      { pickup: { name: "Denver, CO",     lat: 39.7392, lon: -104.9903 },
        dropoff:{ name: "Kansas City, MO",lat: 39.0997, lon: -94.5786 } }
    ]

    commodities = %w[Steel Lumber Produce Electronics Machinery Paper Beverages Furniture DryGoods Pallets]
    weights     = -> { rand(18_000..45_000) }
    statuses    = Load.statuses.keys # e.g. ["planned","in_transit","delivered","dropped"]

    created = 0

    count.times do
      pair = city_pairs.sample

      load = driver.loads.create!(
        commodity:      (defined?(Faker) ? Faker::Commerce.material : commodities.sample),
        weight_lbs:     weights.call,
        pickup_location:  pair[:pickup][:name],
        dropoff_location: pair[:dropoff][:name],
        status:           statuses.sample
      )

      # Set coordinates directly (bypass geocoder)
      load.update_columns(
        pickup_lat:   pair[:pickup][:lat],  pickup_lon:   pair[:pickup][:lon],
        dropoff_lat:  pair[:dropoff][:lat], dropoff_lon:  pair[:dropoff][:lon]
      )

      # Attach a handful of stops that lie near the route corridor (if data exists)
      begin
        buffer_miles = 15
        corridor = RouteCorridor.new(
          pair[:pickup][:lat],  pair[:pickup][:lon],
          pair[:dropoff][:lat], pair[:dropoff][:lon],
          buffer_miles: buffer_miles
        )
        min_lat, max_lat, min_lon, max_lon = corridor.bbox_with_padding

        ra_lat = RestArea.column_names.include?("lat") ? :lat : :latitude
        ra_lon = RestArea.column_names.include?("lon") ? :lon : :longitude
        ws_lat = WeighStation.column_names.include?("lat") ? :lat : :latitude
        ws_lon = WeighStation.column_names.include?("lon") ? :lon : :longitude

        rest_candidates = RestArea.where(ra_lat => min_lat..max_lat, ra_lon => min_lon..max_lon)
        rest_on_route   = rest_candidates.select { |r|
          lat = r.public_send(ra_lat); lon = r.public_send(ra_lon)
          lat && lon && corridor.include_point?(lat, lon)
        }.sample(2)

        weigh_candidates = WeighStation.where(ws_lat => min_lat..max_lat, ws_lon => min_lon..max_lon)
        weigh_on_route   = weigh_candidates.select { |w|
          lat = w.public_send(ws_lat); lon = w.public_send(ws_lon)
          lat && lon && corridor.include_point?(lat, lon)
        }.sample(2)

        truck_candidates = TruckStop.where(latitude: min_lat..max_lat, longitude: min_lon..max_lon)
        truck_on_route   = truck_candidates.select { |t|
          t.latitude && t.longitude && corridor.include_point?(t.latitude, t.longitude)
        }.sample(3)

        (rest_on_route + weigh_on_route + truck_on_route).each do |stop|
          load.load_stops.find_or_create_by!(stoppable: stop)
        end
      rescue NameError
        # RouteCorridor not defined? Just attach a few randoms if available.
        rest_on_route  = RestArea.limit(2).order(Arel.sql("RANDOM()"))
        weigh_on_route = WeighStation.limit(2).order(Arel.sql("RANDOM()"))
        truck_on_route = TruckStop.limit(3).order(Arel.sql("RANDOM()"))
        (rest_on_route + weigh_on_route + truck_on_route).each do |stop|
          load.load_stops.find_or_create_by!(stoppable: stop)
        end
      end

      created += 1
    end

    puts "✅ Created #{created} loads for #{driver.email}."
    puts "   Sign in as: #{driver.email} / password123" if args[:email].nil?
  end

  desc "Delete demo loads (and their stops) for EMAIL (default: demo@example.com)"
  task :clear, [:email] => :environment do |_, args|
    abort("Refusing to run in production.") if Rails.env.production?
    email = (args[:email] || "demo@example.com").to_s
    driver = Driver.find_by(email: email)
    if driver.nil?
      puts "No driver found for #{email}."
      next
    end
    load_ids = driver.loads.pluck(:id)
    LoadStop.where(load_id: load_ids).delete_all
    n = driver.loads.delete_all
    puts "🧹 Deleted #{n} loads (and their stops) for #{email}."
  end
end
