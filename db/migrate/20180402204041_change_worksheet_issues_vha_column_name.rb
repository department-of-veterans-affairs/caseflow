class ChangeWorksheetIssuesVhaColumnName < ActiveRecord::Migration[5.1]
  def change
    rename_column :worksheet_issues, :vha, :omo
  end
end
