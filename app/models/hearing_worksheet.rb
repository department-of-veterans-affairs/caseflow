class HearingWorksheet < ActiveRecord::Base
  self.table_name = "hearings"

  has_many :issues, through: :appeal
  belongs_to :appeal
  belongs_to :user

  # accepts_nested_attributes_for :hearing_worksheet_issues, update_only: true

end
