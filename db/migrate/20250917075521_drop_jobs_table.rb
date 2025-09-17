# db/migrate/20250917075521_drop_jobs_table.rb
class DropJobsTable < ActiveRecord::Migration[8.0]
  def up
    # Drop any views named "jobs" in any schema (Xata creates temp/migration schemas)
    execute <<~SQL
      DO $$
      DECLARE r RECORD;
      BEGIN
        FOR r IN
          SELECT table_schema, table_name
          FROM information_schema.views
          WHERE table_name = 'jobs'
        LOOP
          EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', r.table_schema, r.table_name);
        END LOOP;
      END
      $$;
    SQL

    drop_table :jobs, if_exists: true
  end

  def down
    create_table :jobs do |t|
      t.string :status
      t.timestamps
    end
  end
end
