# frozen_string_literal: true

class CavcReasonsToBasis < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  belongs_to :cavc_dispositions_to_reason
  belongs_to :cavc_selection_basis

  validates :cavc_dispositions_to_reason, presence: true
end
