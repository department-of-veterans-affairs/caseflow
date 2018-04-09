class AddNotesToWorksheetIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :worksheet_issues, :notes, :string
  end
end
