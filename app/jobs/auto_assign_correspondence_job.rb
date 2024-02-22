# frozen_string_literal: true

class AutoAssignCorrespondenceJob < CaseflowJob
  queue_with_priority :low_priority

  def perform(current_user_id:, batch_auto_assignment_attempt_id:)
    CorrespondenceAutoAssigner.new(
      current_user_id: current_user_id,
      batch_auto_assignment_attempt_id: batch_auto_assignment_attempt_id
    ).perform
  rescue StandardError => error
    error_uuid = SecureRandom.uuid
    log_error(error, extra: { error_uuid: error_uuid })
  end
end
