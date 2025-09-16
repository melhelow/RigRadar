
require "csv"

namespace :slurp do
  desc "Upsert TruckStops from lib/csvs/truck_stops_verified.csv"
  task :truck_stops => :environment do
    path = Rails.root.join("lib", "csvs", "truck_stops_verified.csv")
    abort "CSV not found: #{path}" unless File.exist?(path)

    inserted = 0
    updated  = 0

    CSV.foreach(path, headers: true, encoding: "bom|utf-8") do |row|
      lat  = row["Latitude"]&.to_f
      lon  = row["Longitude"]&.to_f
      name = row["Name"]&.to_s&.strip
      next if name.blank? || lat.nil? || lon.nil?

      attrs = {
        name:          name,
        latitude:      lat,
        longitude:     lon,
        street:        row["Street"],
        city:          row["City"],
        state:         row["State"],
        zip_code:      row["Zip_Code"],
        phone:         row["Phone"],
        website:       row["URL"],
        opening_hours: row["Open_Hours"],
        provider:      row["Provider"],
        parking_truck: row["parking_truck"].presence&.to_i,
        parking_rv:    row["parking_rv"].presence&.to_i,
        raw_details:   row["raw_details"]
      }.compact

      attrs[:country] = "US" if TruckStop.column_names.include?("country")
      if TruckStop.column_names.include?("status") && attrs[:status].blank?
        attrs[:status] = "active"
      end
      if TruckStop.column_names.include?("direction_url")
        attrs[:direction_url] = "https://www.google.com/maps/search/?api=1&query=#{lat},#{lon}"
      end

      ts = TruckStop.find_by(name: name, latitude: lat, longitude: lon)
      if ts
        ts.update!(attrs)
        updated += 1
      else
        TruckStop.create!(attrs)
        inserted += 1
      end
    end

    puts "truck_stops: inserted=#{inserted}, updated=#{updated}, total=#{TruckStop.count}"
  end

  desc "Upsert RestAreas from lib/csvs/NTAD_Truck_Stop_Parking.csv"
  task :rest_areas => :environment do
    path = Rails.root.join("lib", "csvs", "NTAD_Truck_Stop_Parking.csv")
    abort "CSV not found: #{path}" unless File.exist?(path)

    upserts = 0
    CSV.foreach(path, headers: true, encoding: "bom|utf-8") do |row|
      lat = row["latitude"] || row["Latitude"]
      lon = row["longitude"] || row["Longitude"]
      next if lat.to_s.strip.empty? || lon.to_s.strip.empty?

      attrs = {
        object_uid:      row["OBJECTID"]&.to_s,
        state_number:    row["state_number"],
        nhs_rest_stop:   row["nhs_rest_stop"],
        highway_route:   row["highway_route"],
        mile_post:       row["mile_post"],
        municipality:    row["municipality"],
        county:          row["county"],
        state:           row["state"],
        lat:             lat,
        lon:             lon,
        number_of_spots: row["number_of_spots"],
        x:               row["x"],
        y:               row["y"],
        name:            row["name"]
      }.compact

      attrs[:name] ||= [attrs[:state], attrs[:highway_route], ("MP #{attrs[:mile_post]}" if attrs[:mile_post])].compact.join(" ")

      rec =
        if attrs[:object_uid].present?
          RestArea.find_or_initialize_by(object_uid: attrs[:object_uid])
        else
          RestArea.find_or_initialize_by(lat: attrs[:lat], lon: attrs[:lon], name: attrs[:name])
        end

      rec.assign_attributes(attrs)
      if rec.changed?
        rec.save!
        upserts += 1
      end
    end

    puts "rest_areas upserted: #{upserts} (total=#{RestArea.count})"
  end

  desc "Upsert WeighStations from lib/csvs/NTAD_Weigh_in_Motion_Stations.csv"
  task :weigh_stations => :environment do
    path = Rails.root.join("lib", "csvs", "NTAD_Weigh_in_Motion_Stations.csv")
    abort "CSV not found: #{path}" unless File.exist?(path)

    upserts = 0
    CSV.foreach(path, headers: true, encoding: "bom|utf-8") do |row|
      lat = row["Latitude"] || row["latitude"]
      lon = row["Longitude"] || row["longitude"]
      next if lat.to_s.strip.empty? || lon.to_s.strip.empty?

      attrs = {
        station_uid:     (row["STATION_ID"] || row["Station_Id"] || row["station_id"])&.to_s,
        concat_id:       row["CONCAT_ID"] || row["Concat_ID"],
        fips_code:       row["FIPS_Code"] || row["FIPS"],
        state:           row["State"] || row["state"],
        functional:      row["FUNCTIONAL"] || row["Functional"],
        lat:             lat,
        lon:             lon,
        counts_year:     row["COUNTS_YEAR"] || row["Counts_Year"],
        sum_weight_year: row["SUM_WEIGHT_YEAR"] || row["Sum_Weight_Year"],
        num_days_active: row["NUM_DAYS_ACTIVE"] || row["Num_Days_Active"],
        x:               row["X"] || row["x"],
        y:               row["Y"] || row["y"],
        name:            row["NAME"] || row["Name"]
      }.compact

      attrs[:name] ||= "Weigh Station #{attrs[:station_uid]}"

      rec =
        if attrs[:station_uid].present?
          WeighStation.find_or_initialize_by(station_uid: attrs[:station_uid])
        else
          WeighStation.find_or_initialize_by(lat: attrs[:lat], lon: attrs[:lon], name: attrs[:name])
        end

      rec.assign_attributes(attrs)
      if rec.changed?
        rec.save!
        upserts += 1
      end
    end

    puts "weigh_stations upserted: #{upserts} (total=#{WeighStation.count})"
  end
end

