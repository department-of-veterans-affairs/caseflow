class DeleteWorksheetIssues < ActiveRecord::Migration[5.1]
  def change
    # Delete issues there were accidentally created by the Status API
    WorksheetIssue.find_each(&:really_destroy!)
  end
end
