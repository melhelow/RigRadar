class SetDefaultAndNotNullOnLoadsStatus < ActiveRecord::Migration[8.0]
  def up
    # Set default for new rows
    change_column_default :loads, :status, 0
    # Backfill existing NULLs so we can enforce NOT NULL
    execute "UPDATE loads SET status = 0 WHERE status IS NULL"
    # Enforce NOT NULL
    change_column_null :loads, :status, false
  end

  def down
    change_column_null :loads, :status, true
    change_column_default :loads, :status, nil
  end
end
