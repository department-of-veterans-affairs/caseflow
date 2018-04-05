class RenameIssuesToWorksheetIssues < ActiveRecord::Migration[5.1]
  def change
    rename_table :issues, :worksheet_issues
  end
end
