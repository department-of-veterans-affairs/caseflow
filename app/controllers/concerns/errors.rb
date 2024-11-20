# frozen_string_literal: true

module Errors
  extend ActiveSupport::Concern
  def invalid_role_error
    render json: {
      "errors": [
        "title": "Role is Invalid",
        "detail": "User is not allowed to perform this action"
      ]
    }, status: :bad_request
  end

  def invalid_task_movement_error
    render json: {
      "errors": [
        "title": "Blocked Legacy Appeal Case Movement is Invalid",
        "detail": "LegacyAppealAssignmentTrackingTask was not created"
      ]
    }, status: :bad_request
  end
end
