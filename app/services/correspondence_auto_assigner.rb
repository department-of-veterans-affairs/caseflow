# frozen_string_literal: true

# Assigns Correspondence ReviewPackageTasks to eligible InboundOpsTeam users.
# (Assigning the Correspondence's ReviewPackageTask is considered assigning the Correspondence.)

class CorrespondenceAutoAssigner
  # rubocop:disable Metrics/MethodLength
  def perform(current_user_id:, batch_auto_assignment_attempt_id:)
    # Don't catch these exceptions here so that if we're being called by a job
    # the job will auto-retry with exponential back-off
    validate_run!(current_user_id, batch_auto_assignment_attempt_id)

    logger.begin

    if !unassigned_review_package_tasks.count.positive?
      logger.error(msg: COPY::BAAA_NO_UNASSIGNED_CORRESPONDENCE)
      return
    end

    if !assignable_user_finder.assignable_users_exist?
      logger.error(msg: COPY::BAAA_USERS_MAX_QUEUE_REACHED)
      return
    end

    begin
      unassigned_review_package_tasks.each do |task|
        # validate a user is able to work the task
        assignee = find_auto_assign_user(task)

        # guard clause if no assignee
        break if assignee.blank?

        assign(task, assignee)
      end

      logger.end
    rescue StandardError => error
      error_uuid = SecureRandom.uuid
      Raven.capture_exception(error, extra: { error_uuid: error_uuid })
      logger.error(msg: "#{COPY::BAAA_ERROR_MESSAGE} (Error code: #{error_uuid})")
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  attr_accessor :batch, :current_user

  def find_auto_assign_user(task)
    started_at = Time.current
    correspondence = task.correspondence
    assignee = assignable_user_finder.get_first_assignable_user(correspondence: correspondence)

    # return last error message for the most recent auto assign error.
    if assignee.blank?
      logger.no_eligible_assignees(
        task: task,
        started_at: started_at,
        unassignable_reason: assignable_user_finder.unassignable_reasons.last
      )
    end
    assignee
  end

  def assign(task, assignee)
    started_at = Time.current
    assign_task_to_user(task, assignee)
    logger.assigned(task: task, started_at: started_at, assigned_to: assignee)
  end

  def assign_task_to_user(task, user)
    task.update!(
      assigned_to: user,
      assigned_at: Time.current,
      assigned_by: current_user,
      assigned_to_type: User.name,
      status: Constants.TASK_STATUSES.assigned
    )
  end

  def unassigned_review_package_tasks
    return [] if FeatureToggle.enabled?(:auto_assign_banner_no_rpt)

    ReviewPackageTask
      .where(status: Constants.TASK_STATUSES.unassigned)
      .preload(:appeal, :assigned_by, :assigned_to, :parent)
      .joins("LEFT JOIN correspondences ON correspondences.id = tasks.appeal_id AND tasks.appeal_type = 'Correspondence'")
      .joins("LEFT JOIN veterans ON veterans.id = correspondences.veteran_id")
      .order('correspondences.va_date_of_receipt ASC')
  end

  def validate_run!(current_user_id, batch_auto_assignment_attempt_id)
    if run_verifier.can_run_auto_assign?(
      current_user_id: current_user_id,
      batch_auto_assignment_attempt_id: batch_auto_assignment_attempt_id
    )
      self.batch = run_verifier.verified_batch
      self.current_user = run_verifier.verified_user
    else
      CorrespondenceAutoAssignLogger.fail_run_validation(
        batch_auto_assignment_attempt_id: batch_auto_assignment_attempt_id,
        msg: run_verifier.err_msg
      )
      fail run_verifier.err_msg
    end
  end

  def logger
    @logger ||= CorrespondenceAutoAssignLogger.new(current_user, batch)
  end

  def assignable_user_finder
    @assignable_user_finder ||= AutoAssignableUserFinder.new(current_user)
  end

  def run_verifier
    @run_verifier ||= CorrespondenceAutoAssignRunVerifier.new
  end
end
