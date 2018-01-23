class PopulateIssueDisposition < ActiveRecord::Migration
  def change
    Hearing.find_each(batch_size: 100) do |hearing|
      hearing.appeal.issues.each do |issue|
        worksheet_issue = WorksheetIssue.find_by(appeal: hearing.appeal, vacols_sequence_id: issue.vacols_sequence_id)
        worksheet_issue.update(disposition: issue.formatted_disposition) if worksheet_issue &&
          worksheet_issue.from_vacols? && !worksheet_issue.disposition
      end
    end
  end
end
