class CleanupRestAreas < ActiveRecord::Migration[7.1]
  def change
    %i[
      county
      municipality
      nhs_rest_stop
      state_number
      objectid   # <-- correct name (NOT object_uid)
      x
      y
      latitude   # safe even if it doesn't exist
      longitude  # safe even if it doesn't exist
    ].each do |col|
      remove_column :rest_areas, col, if_exists: true
    end
  end
end
