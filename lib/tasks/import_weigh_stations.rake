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
      station_id = (row["STATION_ID"] || row["Station_Id"] || row["station_id"])&.to_s
      attrs = {
        station_id:      station_id,
        state:           row["State"] || row["state"],
        functional:      row["FUNCTIONAL"] || row["Functional"],
        lat:             lat,
        lon:             lon,
        name:            row["NAME"] || row["Name"]
      }.compact
      attrs[:name] ||= "Weigh Station #{attrs[:station_id]}"
      rec =
        if attrs[:station_id].present?
          WeighStation.find_or_initialize_by(station_id: attrs[:station_id])
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
