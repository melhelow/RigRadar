# db/migrate/20250917062533_readd_missing_columns_for_ui.rb
class ReaddMissingColumnsForUi < ActiveRecord::Migration[8.0]
  def change
    add_column :rest_areas,  :name,          :string unless column_exists?(:rest_areas,  :name)
    add_column :truck_stops, :website,       :string unless column_exists?(:truck_stops, :website)
    add_column :truck_stops, :direction_url, :string unless column_exists?(:truck_stops, :direction_url)
  end
end
