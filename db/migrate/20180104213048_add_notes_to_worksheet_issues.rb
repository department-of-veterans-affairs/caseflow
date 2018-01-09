class AddNotesToWorksheetIssues < ActiveRecord::Migration
  def change
    add_column :worksheet_issues, :notes, :string
  end
end
