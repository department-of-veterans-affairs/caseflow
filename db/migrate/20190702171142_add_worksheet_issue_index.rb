class AddWorksheetIssueIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :worksheet_issues, :appeal_id, algorithm: :concurrently
    add_index :hearing_locations, :hearing_id, algorithm: :concurrently
    add_index :hearing_locations, :hearing_type, algorithm: :concurrently
  end
end
