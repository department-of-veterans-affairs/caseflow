class HearingWorksheetIssue < ActiveRecord::Base
  belongs_to :hearing_worksheet
  belongs_to :issue

  enum status: {
    allow: 0,
    deny: 1,
    remand: 2,
    dismiss: 3
  }
end
