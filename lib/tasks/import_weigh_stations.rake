# frozen_string_literal: true
require "csv"

namespace :import do
  desc "Import WeighStations from CSV. Usage: bin/rails import:weigh_stations FILE=db/data/NTAD_Weigh_in_Motion_Stations.csv"
  task weigh_stations: :environment do
    file = ENV["FILE"] || "db/data/NTAD_Weigh_in_Motion_Stations.csv"
    abort "CSV not found: #{file}" unless File.exist?(file)

    upserts = 0
    CSV.foreach(file, headers: true, encoding: "bom|utf-8") do |row|
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

    puts "WeighStations upserted: #{upserts}"
    puts "Total WeighStations: #{WeighStation.count}"
  end
end
