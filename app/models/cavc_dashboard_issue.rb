# frozen_string_literal: true

class CavcDashboardIssue < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  belongs_to :cavc_dashboard
  has_one :cavc_dashboard_disposition

  validates :cavc_dashboard, presence: true
end
