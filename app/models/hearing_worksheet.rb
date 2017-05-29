class HearingWorksheet < ActiveRecord::Base
  self.table_name = "hearings"

  belongs_to :appeal
  belongs_to :user # the judge
  has_many :hearing_worksheet_issues, through: :appeal, source: :issues

end
