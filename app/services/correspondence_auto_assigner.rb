# frozen_string_literal: true

# :reek:InstanceVariableAssumption
class CorrespondenceAutoAssigner
  def initialize(current_user_id:, batch_auto_assignment_attempt_id:)
    @current_user = User.find(current_user_id)
    @batch = BatchAutoAssignmentAttempt.find_by(user: @current_user, id: batch_auto_assignment_attempt_id)
  end

  def perform
    logger.begin

    # Manual error trigger for testing purposes
    if FeatureToggle.enabled?(:auto_assign_banner_failure) && !Rails.env.production?
      fail StandardError
    end

    if !unassigned_review_package_tasks.count.positive?
      logger.error(msg: COPY::BAAA_NO_UNASSIGNED_CORRESPONDENCE)
      return
    end

    if !assignable_user_finder.assignable_users_exist?
      logger.error(msg: COPY::BAAA_USERS_MAX_QUEUE_REACHED)
      return
    end

    unassigned_review_package_tasks.each do |task|
      assign(task)
    end
    logger.end
  rescue StandardError => error
    error_uuid = SecureRandom.uuid
    Raven.capture_exception(error, extra: { error_uuid: error_uuid })
    logger.error(msg: COPY::BAAA_ERROR_MESSAGE + " (Error code:#{error_uuid})", extras: { error_uuid: error_uuid })
  end

  private

  def assign(task)
    started_at = Time.current

    correspondence = task.correspondence
    assignee = assignable_user_finder.get_first_assignable_user(correspondence: correspondence)

    if assignee.blank?
      logger.no_eligible_assignees(task: task, started_at: started_at)
      return
    end

    assign_task_to_user(task, assignee)
    logger.assigned(task: task, started_at: started_at, assigned_to: assignee)
  end

  def assign_task_to_user(task, user)
    task.update!(
      assigned_to: user,
      assigned_at: Time.current,
      assigned_by: @current_user,
      assigned_to_type: User.name,
      status: Constants.TASK_STATUSES.assigned
    )
  end

  def unassigned_review_package_tasks
    return @unassigned_review_package_tasks if @unassigned_review_package_tasks.present?

    tasks = ReviewPackageTask
      .where(status: "unassigned")
      .includes(:correspondence)
      .references(:correspondence)
      .merge(Correspondence.order(va_date_of_receipt: :desc))

    # Jobs run synchronously in testing and development environments - limit to 10 to prevent timeouts
    tasks = if !Rails.env.production?
              if FeatureToggle.enabled?(:auto_assign_banner_no_rpt)
                []
              else
                tasks.limit(10)
              end
            end

    @unassigned_review_package_tasks = tasks
  end

  def logger
    @logger ||= CorrespondenceAutoAssignLogger.new(@current_user, @batch)
  end

  def assignable_user_finder
    @assignable_user_finder ||= AutoAssignableUserFinder.new
  end
end
