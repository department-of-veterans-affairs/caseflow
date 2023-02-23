# frozen_string_literal: true

class CavcDispositionsToReason < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  belongs_to :cavc_dashboard_disposition
  belongs_to :cavc_decision_reason
  belongs_to :cavc_selection_basis

  validates :cavc_dashboard_disposition, presence: true

end
