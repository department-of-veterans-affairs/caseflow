class ChangeWorksheetIssuesVhaColumnName < ActiveRecord::Migration
  def change
    rename_column :worksheet_issues, :vha, :omo
  end
end
