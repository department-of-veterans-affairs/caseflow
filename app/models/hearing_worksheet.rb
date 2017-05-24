class HearingWorksheet < ActiveRecord::Base
  belongs_to :hearing
  has_many :hearing_worksheet_issues

  alias_attribute :issues, :hearing_worksheet_issues
end
