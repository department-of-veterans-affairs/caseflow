class WorksheetIssueArraysToStrings < ActiveRecord::Migration[5.1]
  def change
    change_column :worksheet_issues, :levels, :string
    change_column :worksheet_issues, :description, :string
  end
end
