class AddDeletedAtToWorksheetIssues < ActiveRecord::Migration
  def change
    add_column :worksheet_issues, :deleted_at, :datetime
  end
end
