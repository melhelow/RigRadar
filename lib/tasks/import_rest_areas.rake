# frozen_string_literal: true
require "csv"

namespace :import do
  desc "Import RestAreas from CSV. Usage: bin/rails import:rest_areas FILE=db/data/NTAD_Truck_Stop_Parking.csv"
  task rest_areas: :environment do
    file = ENV["FILE"] || "db/data/NTAD_Truck_Stop_Parking.csv"
    abort "CSV not found: #{file}" unless File.exist?(file)

    upserts = 0
    CSV.foreach(file, headers: true, encoding: "bom|utf-8") do |row|
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

    puts "RestAreas upserted: #{upserts}"
    puts "Total RestAreas: #{RestArea.count}"
  end
end
