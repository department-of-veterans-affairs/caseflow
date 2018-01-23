class AddDispositionToWorksheetIssues < ActiveRecord::Migration
  def change
    add_column :worksheet_issues, :disposition, :string
  end
end

