# lib/tasks/csv_import.rake
# Usage:
#   bundle exec rails 'csv:import[lib/csvs/truck_stops_verified.csv,truck_stops,1000]'
#   bundle exec rails 'csv:import[lib/csvs/NTAD_Truck_Stop_Parking.csv,rest_areas,1000]'
#   bundle exec rails 'csv:import[lib/csvs/NTAD_Weigh_in_Motion_Stations.csv,weigh_stations,1000]'

namespace :csv do
  # Per-table header -> DB column aliases (headers are normalized to snake_case)
  TABLE_ALIASES = {
    "truck_stops" => {
      # common coordinate headers → DB column names used by your model
      "lat"        => "latitude",
      "lon"        => "longitude",

      # optional fields that your DB may or may not have
      "url"        => "direction_url",
      "open_hours" => "opening_hours"
    },

    "rest_areas" => {
      # NTAD fields → your schema
      "nhs_rest_stop" => "name",
      "latitude"      => "lat",
      "longitude"     => "lon",
      "y"             => "lat", # some datasets use y/x
      "x"             => "lon"
    },

    "weigh_stations" => {
      # coordinates
      "latitude"  => "lat",
      "longitude" => "lon",
      "y"         => "lat",
      "x"         => "lon",

      # accept many possible headers for the station id
      "station_id"      => "station_id",
      "stationid"       => "station_id",
      "station"         => "station_id",
      "station_no"      => "station_id",
      "station_number"  => "station_id",
      "stationnum"      => "station_id",
      "stn_id"          => "station_id",
      "stnid"           => "station_id",
      "site_id"         => "station_id",
      "site_no"         => "station_id"
    }
  }.freeze

  # Columns we require per table (after fallbacks are applied).
  REQUIRED = {
    "truck_stops" => %w[name]
  }.freeze

  desc "Import a CSV into a table. Usage: rails 'csv:import[CSV_PATH,TABLE_NAME,BATCH_SIZE]'"
  task :import, [ :csv_path, :table_name, :batch_size ] => :environment do |_, args|
    require "csv"

    csv_path = args[:csv_path]  or abort("CSV_PATH is required, e.g. lib/csvs/truck_stops_verified.csv")
    table    = args[:table_name] or abort("TABLE_NAME is required, e.g. truck_stops")
    batch_sz = (args[:batch_size] || 1000).to_i

    klass = Class.new(ActiveRecord::Base) { self.table_name = table }
    cols_in_db = klass.column_names
    normalizer = ->(h) { h.to_s.strip.downcase.gsub(/[^\w]+/, "_").gsub(/^_+|_+$/, "") }

    # Peek headers once
    headers = CSV.open(csv_path, headers: true) { |io| io.first&.headers }
    abort("No headers found in #{csv_path}") if headers.nil? || headers.empty?

    alias_map = TABLE_ALIASES.fetch(table, {})

    # original header -> destination DB column (or identity if no alias)
    mapped = headers.map do |h|
      n = normalizer.call(h)
      [ h, alias_map[n] || n ]
    end.to_h

    # DB columns we will actually insert into (skip any that don't exist)
    import_cols = (mapped.values & cols_in_db)
    abort("None of the CSV columns match columns in #{table}. Table has: #{cols_in_db.join(', ')}") if import_cols.empty?

    has_created_at = cols_in_db.include?("created_at")
    has_updated_at = cols_in_db.include?("updated_at")

    total  = 0
    now    = Time.current
    buffer = []
    skipped_missing = 0

    # helper: find a value in the row by normalized header name
    fetch_by_norm = ->(src_hash, norm_name) do
      pair = src_hash.find { |h, _| normalizer.call(h) == norm_name }
      pair&.last
    end

    CSV.foreach(csv_path, headers: true) do |row|
      src = row.to_h
      rec = {}

      # populate record fields from CSV headers that map to DB columns
      import_cols.each do |col|
        # choose the first CSV header that maps to this DB column
        orig = headers.find { |h| mapped[h] == col }
        rec[col] = src[orig]
      end

      # -------- table-specific fixes / fallbacks --------
      case table
      when "truck_stops"
        # Ensure name present (DB requires it). Try common name-ish fields;
        # then synthesize from city/state or coordinates.
        if rec["name"].to_s.strip.empty?
          name_guess = %w[name facility site_name location title provider]
                         .map { |k| fetch_by_norm.call(src, k) }
                         .compact
                         .find { |v| !v.to_s.strip.empty? }

          rec["name"] =
            (name_guess.presence ||
             [ "Truck Stop", rec["city"], rec["state"] ].compact.join(" - ").presence ||
             (
               if rec["latitude"].present? && rec["longitude"].present?
                 "Truck Stop @ #{rec['latitude']},#{rec['longitude']}"
               end
             ) ||
             "Truck Stop")
        end

      when "rest_areas"
        # Nothing required; UI already handles missing name as "Rest Area".
        # Just ensure lat/lon get mapped through alias_map.

      when "weigh_stations"
        # If station_id didn't map directly, try common alternatives
        if rec["station_id"].to_s.strip.empty?
          id_guess = %w[
            station_id stationid station station_no station_number
            stationnum stn_id stnid site_id site_no
          ].map { |k| fetch_by_norm.call(src, k) }
           .compact
           .find { |v| !v.to_s.strip.empty? }
          rec["station_id"] = id_guess if id_guess.present?
        end

        # Prefer "Weigh Station #<id>" for the name when possible
        if rec["name"].to_s.strip.empty?
          rec["name"] = rec["station_id"].present? ? "Weigh Station ##{rec['station_id']}" : "Weigh Station"
        end
      end
      # --------------------------------------------------

      rec["created_at"] ||= now if has_created_at
      rec["updated_at"]  =  now if has_updated_at

      # turn empty strings into NULLs
      rec.each { |k, v| rec[k] = nil if v.is_a?(String) && v.strip == "" }

      # Skip rows missing required fields after fallbacks
      required = Array(REQUIRED[table])
      if required.any? && required.any? { |k| rec[k].to_s.strip.empty? }
        skipped_missing += 1
        next
      end

      buffer << rec

      if buffer.size >= batch_sz
        klass.insert_all(buffer)
        total += buffer.size
        buffer.clear
      end
    end

    if buffer.any?
      klass.insert_all(buffer)
      total += buffer.size
    end

    puts "Imported #{total} rows into #{table} from #{csv_path}"
    puts "Matched columns: #{import_cols.join(', ')}"
    skipped = (mapped.values.uniq - import_cols)
    puts "Skipped CSV columns (not in table): #{skipped.join(', ')}" if skipped.any?
    puts "Skipped rows missing required fields: #{skipped_missing}" if skipped_missing > 0
  end
end
