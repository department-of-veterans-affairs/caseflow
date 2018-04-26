class AddDispositionToWorksheetIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :worksheet_issues, :disposition, :string
  end
end

