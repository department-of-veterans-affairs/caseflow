class DeleteWorksheetIssues < ActiveRecord::Migration
  def change
    # Delete issues there were accidentally created by the Status API
    WorksheetIssue.all.each(&:really_destroy!)
  end
end
