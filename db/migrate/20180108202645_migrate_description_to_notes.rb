class MigrateDescriptionToNotes < ActiveRecord::Migration[5.1]
  def change
    WorksheetIssue.update_all("notes=description")
  end
end
