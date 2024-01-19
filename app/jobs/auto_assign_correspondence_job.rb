# frozen_string_literal: true

class AutoAssignCorrespondenceJob < CaseflowJob
  queue_with_priority :low_priority

  def perform(current_user_id:)
    correspondence_auto_assigner.do_auto_assignment(current_user_id: current_user_id)
  rescue StandardError => error
    log_error(error)
  end

  private

  def
    @correspondence_auto_assigner ||= CorrespondenceAutoAssigner.new
  end
end
