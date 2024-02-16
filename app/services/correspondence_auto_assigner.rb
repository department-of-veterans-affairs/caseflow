# frozen_string_literal: true

class CorrespondenceAutoAssigner
  def initialize(current_user_id:)
    @current_user = User.find(current_user_id)
  end

  def perform
    logger.begin

    if !unassigned_review_package_tasks.count.positive?
      logger.error(msg: "No review package tasks to assign")
      return
    end

    if !assignable_user_finder.assignable_users_exist?
      logger.error(msg: "No auto-assignable users available")
      return
    end

    unassigned_review_package_tasks.each do |task|
      assign(task)
    end

    logger.end
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
    @unassigned_review_package_tasks ||= ReviewPackageTask
      .where(status: "unassigned")
      .includes(:correspondence)
      .references(:correspondence)
      .merge(Correspondence.order(va_date_of_receipt: :desc))
  end

  def logger
    @logger ||= CorrespondenceAutoAssignLogger.new(@current_user)
  end

  def assignable_user_finder
    @assignable_user_finder ||= AutoAssignableUserFinder.new
  end
end
