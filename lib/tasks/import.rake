# lib/tasks/import.rake
namespace :data do
  desc "Import jobs from lib/csvs/export.csv"
  task import_jobs: :environment do
    require "csv"
    path = Rails.root.join("lib", "csvs", "export.csv")
    rows = []
    now  = Time.current

    CSV.foreach(path, headers: true) do |r|
      rows << {
        status:     r["status"],  # add more columns if your CSV has them
        created_at: now,
        updated_at: now
      }
    end

    if rows.empty?
      puts "No rows found at #{path}"
    else
      Job.insert_all(rows)  # lets Postgres assign IDs
      puts "Inserted #{rows.size} Job rows from #{path}"
    end
  end
end
