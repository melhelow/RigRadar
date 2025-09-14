# lib/tasks/import_verified_truckstops.rake
require "csv"

namespace :import do
  desc "Import cleaned truck stops into truck_stops (schema-safe)"
  task :truckstops_verified, [ :path ] => :environment do |_t, args|
  path = args[:path] || "db/data/truck_stops_verified.csv"
  abort "CSV not found: #{path}" unless File.exist?(path)

  keymap = {
    "Name"=>"name", "Latitude"=>"latitude", "Longitude"=>"longitude",
    "Street"=>"street", "City"=>"city", "State"=>"state", "Zip_Code"=>"zip_code",
    "Phone"=>"phone", "URL"=>"website", "Open_Hours"=>"opening_hours",
    "Provider"=>"provider",
    "parking_truck"=>"parking_truck", "parking_rv"=>"parking_rv",
    "raw_details"=>"raw_details"
  }

  model_keys = TruckStop.column_names.map(&:to_s)
  inserted = 0; updated = 0

  CSV.foreach(path, headers: true) do |row|
    lat  = row["Latitude"]&.to_f
    lon  = row["Longitude"]&.to_f
    name = row["Name"]

    attrs = keymap.each_with_object({}) do |(csv, attr), h|
      v = row[csv]
      v = v.to_f if %w[latitude longitude].include?(attr) && v.present?
      v = v.to_i if %w[parking_truck parking_rv].include?(attr) && v.present?
      h[attr] = v
    end

      # Defaults not in CSV
      attrs["country"] = "US" if model_keys.include?("country")
      attrs["status"]  = "active" if model_keys.include?("status") && attrs["status"].blank?
      if lat && lon && model_keys.include?("direction_url")
        attrs["direction_url"] = "https://www.google.com/maps/search/?api=1&query=#{lat},#{lon}"
      end

      attrs.slice!(*model_keys) # write only columns that exist

      # Upsert by unique identity (name+lat+lon)
      ts = TruckStop.find_by(name: name, latitude: lat, longitude: lon)
      if ts
        ts.update!(attrs); updated += 1
      else
        TruckStop.create!(attrs); inserted += 1
      end
    end

    puts "truck_stops: inserted=#{inserted}, updated=#{updated}, total=#{TruckStop.count}"
  end
end
