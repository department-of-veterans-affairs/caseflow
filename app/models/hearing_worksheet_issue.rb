class HearingWorksheetIssue < ActiveRecord::Base
  has_one :hearing_worksheet
  has_one :issue
end
