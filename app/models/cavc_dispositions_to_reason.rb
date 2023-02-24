# frozen_string_literal: true

class CavcDispositionsToReason < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  belongs_to :cavc_dashboard_disposition
  validates :cavc_dashboard_disposition, presence: true
end
