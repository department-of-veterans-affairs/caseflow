class RenameIssuesToWorksheetIssues < ActiveRecord::Migration
  def change
    rename_table :issues, :worksheet_issues
  end
end
