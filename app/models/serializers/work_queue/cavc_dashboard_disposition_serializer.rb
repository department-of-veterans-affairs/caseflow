# frozen_string_literal: true

class WorkQueue::CavcDashboardDispositionSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :cavc_dashboard_id
  attribute :cavc_dashboard_issue_id
  attribute :request_issue_id
  attribute :disposition
  attribute :cavc_dispositions_to_reasons
end
