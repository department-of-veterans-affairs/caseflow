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
  attribute :cavc_dashboard_issues
  attribute :cavc_decision_date
  attribute :cavc_docket_number
  attribute :cavc_remand
  attribute :joint_motion_for_remand

  attribute :remand_request_issues
end
