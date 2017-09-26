class AddIndexDeletedAtToWorksheetIssues < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    # This allows PostgreSQL to build the index without locking in a way
    # that prevent concurrent inserts, updates, or deletes on the table.
    # Standard indexes lock out writes (but not reads) on the table.
    add_index :worksheet_issues, :deleted_at, algorithm: :concurrently
  end
end
