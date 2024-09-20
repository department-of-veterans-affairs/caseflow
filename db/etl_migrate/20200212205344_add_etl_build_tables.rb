# frozen_string_literal: true

class AddEtlBuildTables < ActiveRecord::Migration[5.2]
  def change
    create_table :etl_builds, comment: "ETL build metadata for each job" do |t|
      t.datetime "started_at", comment: "Build start time (usually identical to created_at)"
      t.datetime "finished_at", comment: "Build end time"
      t.string "status", comment: "Enum value: running, complete, error"
      t.string "comments", comment: "Ad hoc comments (e.g. error message)"
      t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
      t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"

      t.index ["status"]
      t.index ["created_at"]
      t.index ["updated_at"]
      t.index ["started_at"]
      t.index ["finished_at"]
    end

    create_table :etl_build_tables, comment: "ETL table metadata, one for each table per-build" do |t|
      t.bigint "etl_build_id", null: false, comment: "PK of the etl_build"
      t.datetime "started_at", comment: "Build start time (usually identical to created_at)"
      t.datetime "finished_at", comment: "Build end time"
      t.string "table_name", comment: "Name of the ETL table"
      t.string "status", comment: "Enum value: running, complete, error"
      t.string "comments", comment: "Ad hoc comments (e.g. error message)"
      t.bigint "rows_inserted", comment: "Number of new rows"
      t.bigint "rows_updated", comment: "Number of rows changed"
      t.bigint "rows_deleted", comment: "Number of rows deleted"
      t.bigint "rows_rejected", comment: "Number of rows skipped"
      t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
      t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"

      t.index ["etl_build_id"]
      t.index ["table_name"]
      t.index ["status"]
      t.index ["created_at"]
      t.index ["updated_at"]
      t.index ["started_at"]
      t.index ["finished_at"]
    end
  end
end
