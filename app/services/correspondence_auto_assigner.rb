# frozen_string_literal: true

class CorrespondenceAutoAssigner
  def initialize(current_user_id:)
    @current_user = User.find(current_user_id)
  end

  def perform
    if !unassigned_review_package_tasks.count.positive?
      return
    end

    if !assignable_user_finder.assignable_users_exist?
      return
    end

    unassigned_review_package_tasks.each do |task|
      assign(task)
    end
  end

  private

  def assign(task)
    assignee = assignable_user_finder.get_first_assignable_user(correspondence: task.correspondence)
    if assignee.blank?
      return
    end

    assign_task_to_user(task, assignee)
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
