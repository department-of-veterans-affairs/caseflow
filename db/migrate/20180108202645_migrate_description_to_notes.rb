class MigrateDescriptionToNotes < ActiveRecord::Migration
  def change
    WorksheetIssue.find_each do |worksheet_issue|
      worksheet_issue.update_attributes! :notes => worksheet_issue.description
    end
  end
end
