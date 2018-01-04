class RenameIssuesFields < ActiveRecord::Migration
  def change
    rename_column :worksheet_issues, :description, :notes
  end
end
