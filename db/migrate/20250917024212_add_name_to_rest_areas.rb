class AddNameToRestAreas < ActiveRecord::Migration[8.0]
  def up
    add_column :rest_areas, :name, :string unless column_exists?(:rest_areas, :name)
  end
  def down
    remove_column :rest_areas, :name if column_exists?(:rest_areas, :name)
  end
end
