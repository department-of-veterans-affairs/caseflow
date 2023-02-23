# frozen_string_literal: true

class CavcDispositionsToReason < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  belongs_to :cavc_dashboard_dispositions
  validates :cavc_dashboard_dispositions, presence: true

end
