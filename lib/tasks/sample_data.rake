# lib/tasks/sample_data.rake
desc "Fill the database with sample data (POIs + demo loads). Run: `bin/rails sample_data` or `bundle exec rake sample_data`"
task sample_data: :environment do
  abort("Refusing to run in production.") if Rails.env.production?

  puts "== Preparing database =="
  # Only invoke once per process
  Rake::Task["db:prepare"].invoke unless Rake::Task["db:prepare"].already_invoked

  # --- Import POIs if files exist (skip if missing) ---
  rest_csv  = Rails.root.join("db/data/NTAD_Truck_Stop_Parking.csv")
  weigh_csv = Rails.root.join("db/data/NTAD_Weigh_in_Motion_Stations.csv")
  ts_csv    = Rails.root.join("db/data/truck_stops_verified.csv")

  if File.exist?(rest_csv)
    puts "== Importing Rest Areas from #{rest_csv} =="
    ENV["FILE"] = rest_csv.to_s
    Rake::Task["import:rest_areas"].reenable
    Rake::Task["import:rest_areas"].invoke
  else
    puts "⚠️  Skipping rest areas (#{rest_csv} not found)"
  end

  if File.exist?(weigh_csv)
    puts "== Importing Weigh Stations from #{weigh_csv} =="
    ENV["FILE"] = weigh_csv.to_s
    Rake::Task["import:weigh_stations"].reenable
    Rake::Task["import:weigh_stations"].invoke
  else
    puts "⚠️  Skipping weigh stations (#{weigh_csv} not found)"
  end

  if File.exist?(ts_csv)
    puts "== Importing Truck Stops from #{ts_csv} =="
    Rake::Task["import:truckstops_verified"].reenable
    Rake::Task["import:truckstops_verified"].invoke(ts_csv.to_s)
  else
    puts "⚠️  Skipping truck stops (#{ts_csv} not found)"
  end

  # --- Demo loads for a demo driver ---
  puts "== Creating demo loads =="
  Rake::Task["sample:load"].reenable
  Rake::Task["sample:load"].invoke(10, "demo@example.com")

  puts "✅ Sample data ready. Sign in: demo@example.com / password123"
end

# Optional alias so `db:sample_data` also works
namespace :db do
  task sample_data: :environment do
    Rake::Task["sample_data"].invoke
  end
end
