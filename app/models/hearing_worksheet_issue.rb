class HearingWorksheetIssue < ActiveRecord::Base
  self.table_name = "issues"

  belongs_to :hearing_worksheet
  belongs_to :issue

  enum hearing_worksheet_status: {
    allow: 0,
    deny: 1,
    remand: 2,
    dismiss: 3
  }
end
