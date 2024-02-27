# frozen_string_literal: true

class CorrespondenceAutoAssignRunVerifier
  attr_accessor :verified_batch, :verified_user, :err_msg

  def can_run_auto_assign?(current_user_id:, batch_auto_assignment_attempt_id:)
    verify_feature_toggles &&
      verify_id_params(current_user_id, batch_auto_assignment_attempt_id) &&
      verify_no_other_jobs_running
  end

  def min_minutes_elapsed_batch_attempt
    Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.timing.min_minutes_elapsed_batch_attempt
  end

  def min_minutes_elapsed_individual_attempt
    Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.timing.min_minutes_elapsed_individual_attempt
  end

  private

  def verify_feature_toggles
    if !Rails.env.production? && FeatureToggle.enabled?(:auto_assign_banner_failure)
      self.err_msg = "Failing due to feature toggle"
      return false
    end

    true
  end

  def verify_id_params(current_user_id, batch_auto_assignment_attempt_id)
    self.verified_user = User.find_by(id: current_user_id)
    if verified_user.blank?
      self.err_msg = "User does not exist"
      return false
    end

    self.verified_batch = BatchAutoAssignmentAttempt.find_by(user: verified_user, id: batch_auto_assignment_attempt_id)
    if verified_batch.blank?
      self.err_msg = "BatchAutoAssignmentAttempt does not exist"
      return false
    end

    true
  end

  def verify_no_other_jobs_running
    if assignment_already_running?
      self.err_msg = "Auto assignment already in progress"
      return false
    end

    true
  end

  def assignment_already_running?
    last_assignment = IndividualAutoAssignmentAttempt.last

    # Safe to move forward if we haven't seen any assignment attempts for the past X minutes
    return true if last_assignment&.completed_at.present? &&
                   ((Time.current - last_assignment.completed_at)/60) < min_minutes_elapsed_individual_attempt

    # Safe to move forward if the last batch was started more than Y minutes ago
    BatchAutoAssignmentAttempt
      .where.not(id: verified_batch.id)
      .where(status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.started)
      .exists?(["started_at < ?", min_minutes_elapsed_batch_attempt.minutes.ago])
  end
end
