# frozen_string_literal: true

class WorkQueue::CavcDashboardSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :board_decision_date
  attribute :board_docket_number
  attribute :cavc_dashboard_dispositions do |object|
    object.cavc_dashboard_dispositions.map do |cdd|
      WorkQueue::CavcDashboardDispositionSerializer.new(cdd).serializable_hash[:data][:attributes]
    end
  end
  attribute :cavc_dashboard_issues do |object|
    object.cavc_dashboard_issues.order(:id)
  end
  attribute :cavc_decision_date
  attribute :cavc_docket_number
  attribute :cavc_remand
  attribute :joint_motion_for_remand

  attribute :remand_request_issues do |object|
    object.remand_request_issues.map do |issue|
      {
        id: issue.id,
        benefit_type: issue.benefit_type,
        description: issue.description,
      }
    end
  end
end
