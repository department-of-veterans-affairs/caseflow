class CreateEtlSchemas < ActiveRecord::Migration[5.1]
  # "schemas" are postgresql namespaces. The default is "public" but we name them for the etl db.
  # However, Rails does not support them natively in AR so we just execute SQL.

  def up
    safety_assured do
      execute "CREATE SCHEMA etl" # metadata
      execute "CREATE SCHEMA ama" # appeals data
    end
  end

  def down
    safety_assured do
      execute "DROP SCHEMA ama"
      execute "DROP SCHEMA etl"
    end
  end
end
