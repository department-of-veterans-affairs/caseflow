class HearingWorksheet < ActiveRecord::Base
  belongs_to :hearing
  has_many :hearing_worksheet_issues

  accepts_nested_attributes_for :hearing_worksheet_issues, update_only: true

  alias_attribute :issues, :hearing_worksheet_issues
end
