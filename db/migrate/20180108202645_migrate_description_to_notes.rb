class MigrateDescriptionToNotes < ActiveRecord::Migration
  def change
    WorksheetIssue.update_all("notes=description")
  end
end
