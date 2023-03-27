# frozen_string_literal: true

class CavcDispositionsToReason < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  belongs_to :cavc_dashboard_disposition
  belongs_to :cavc_decision_reason
  has_many :cavc_reasons_to_bases, dependent: :destroy
  has_many :cavc_selection_bases, through: :cavc_reasons_to_bases

  validates :cavc_dashboard_disposition, presence: true
end
