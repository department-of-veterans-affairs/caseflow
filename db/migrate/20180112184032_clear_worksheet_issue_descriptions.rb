class ClearWorksheetIssueDescriptions < ActiveRecord::Migration[5.1]
  def change
    WorksheetIssue.update_all(description: nil)
  end
end
