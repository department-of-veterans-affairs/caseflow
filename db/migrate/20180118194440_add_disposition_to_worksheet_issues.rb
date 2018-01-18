class AddDispositionToWorksheetIssues < ActiveRecord::Migration
  def change
    add_column :worksheet_issues, :disposition, :string

    Hearing.all.each do |hearing|
      hearing.appeal.issues.each do |issue|
        WorksheetIssue.find_by(appeal: appeal, vacols_sequence_id: issue.vacols_sequence_id)
          .update(disposition: issue.formatted_disposition)
      end
    end
  end
end

