class AddDeletedAtToWorksheetIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :worksheet_issues, :deleted_at, :datetime
  end
end
