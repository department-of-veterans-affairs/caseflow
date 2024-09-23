# frozen_string_literal: true

class AutoAssignCorrespondenceJob < CaseflowJob
  queue_with_priority :low_priority

  def perform(current_user_id:, batch_auto_assignment_attempt_id:)
    correspondence_auto_assigner.perform(
      current_user_id: current_user_id,
      batch_auto_assignment_attempt_id: batch_auto_assignment_attempt_id
    )
  end

  private

  def correspondence_auto_assigner
    @correspondence_auto_assigner ||= CorrespondenceAutoAssigner.new
  end
end
