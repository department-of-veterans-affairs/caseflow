# frozen_string_literal: true

class CavcDashboardDisposition < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  belongs_to :cavc_remand

  validates :cavc_remand, :disposition, presence: true

  enum disposition: {
    Constants.CAVC_DASHBOARD_DISPOSITIONS.abandoned.to_sym => Constants.CAVC_DASHBOARD_DISPOSITIONS.abandoned,
    Constants.CAVC_DASHBOARD_DISPOSITIONS.affirmed.to_sym => Constants.CAVC_DASHBOARD_DISPOSITIONS.affirmed,
    Constants.CAVC_DASHBOARD_DISPOSITIONS.dismissed.to_sym => Constants.CAVC_DASHBOARD_DISPOSITIONS.dismissed,
    Constants.CAVC_DASHBOARD_DISPOSITIONS.settled.to_sym => Constants.CAVC_DASHBOARD_DISPOSITIONS.settled,
    Constants.CAVC_DASHBOARD_DISPOSITIONS.reversed.to_sym => Constants.CAVC_DASHBOARD_DISPOSITIONS.reversed,
    Constants.CAVC_DASHBOARD_DISPOSITIONS.vacated_and_remanded.to_sym =>
      Constants.CAVC_DASHBOARD_DISPOSITIONS.vacated_and_remanded,
    Constants.CAVC_DASHBOARD_DISPOSITIONS.n_a => Constants.CAVC_DASHBOARD_DISPOSITIONS.n_a
  }
end
