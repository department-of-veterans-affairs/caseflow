class ClearWorksheetIssueDescriptions < ActiveRecord::Migration
  def change
    WorksheetIssue.update_all(description: nil)
  end
end
