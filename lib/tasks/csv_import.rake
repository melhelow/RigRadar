# lib/tasks/csv_import.rake
namespace :csv do
  # Map variant CSV headers to your DB column names.
  # This lets CSVs that provide latitude/longitude (or x/y) still populate lat/lon,
  # and maps rest-area "nhs_rest_stop" to your "name" column.
  ALIAS_MAP = {
    "latitude"      => "lat",
    "longitude"     => "lon",
    "y"             => "lat", # some datasets use y/x
    "x"             => "lon",
    "nhs_rest_stop" => "name"
  }.freeze

  desc "Import a CSV into a table. Usage: rails 'csv:import[CSV_PATH,TABLE_NAME,BATCH_SIZE]'"
  task :import, [ :csv_path, :table_name, :batch_size ] => :environment do |_, args|
    require "csv"

    csv_path = args[:csv_path]  || abort("CSV_PATH is required, e.g. lib/csvs/truck_stops_verified.csv")
    table    = args[:table_name] || abort("TABLE_NAME is required, e.g. truck_stops")
    batch_sz = (args[:batch_size] || 1000).to_i

    # Anonymous AR model for the target table
    klass = Class.new(ActiveRecord::Base) { self.table_name = table }

    cols_in_db = klass.column_names
    normalizer = ->(h) { h.to_s.strip.downcase.gsub(/[^\w]+/, "_").gsub(/^_+|_+$/, "") }

    # Read headers once
    headers = CSV.open(csv_path, headers: true) { |io| io.first&.headers }
    abort("No headers found in #{csv_path}") if headers.nil? || headers.empty?

    # Map each original CSV header -> normalized/aliased DB column name
    mapped = headers.map do |h|
      n = normalizer.call(h)
      [ h, ALIAS_MAP.fetch(n, n) ]
    end.to_h

    # Final set of DB columns we will insert into
    import_cols = (mapped.values & cols_in_db)
    abort("None of the CSV columns match columns in #{table}. Table has: #{cols_in_db.join(', ')}") if import_cols.empty?

    has_created_at = cols_in_db.include?("created_at")
    has_updated_at = cols_in_db.include?("updated_at")

    total  = 0
    now    = Time.current
    buffer = []

    CSV.foreach(csv_path, headers: true) do |row|
      src = row.to_h
      rec = {}

      import_cols.each do |col|
        # Pick the first CSV header that maps to this DB column
        orig = headers.find { |h| mapped[h] == col }
        rec[col] = src[orig]
      end

      rec["created_at"] ||= now if has_created_at
      rec["updated_at"]  =  now if has_updated_at

      rec.each { |k, v| rec[k] = nil if v.is_a?(String) && v.strip == "" }
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
    skipped = mapped.values.uniq - import_cols
    puts "Skipped CSV columns (not in table): #{skipped.join(', ')}" if skipped.any?
  end
end
