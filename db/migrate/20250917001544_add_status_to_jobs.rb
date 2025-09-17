
class AddStatusToJobs < ActiveRecord::Migration[8.0]
  def up
    unless table_exists?(:jobs)
      create_table :jobs do |t|
        t.string :status
        t.timestamps
      end
    else
      add_column :jobs, :status, :string unless column_exists?(:jobs, :status)
    end
  end

  def down
    if column_exists?(:jobs, :status)
      remove_column :jobs, :status
    elsif table_exists?(:jobs)
      drop_table :jobs
    end
  end
end
