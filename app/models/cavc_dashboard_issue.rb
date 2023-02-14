# frozen_string_literal: true

class CavcDashboardIssue < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  belongs_to :cavc_dashboard

  validates :cavc_dashboard, presence: true
end
