# frozen_string_literal: true

##
# Checks for all open tasks assigned to inactive users.

class TasksAssignedToInactiveUsersChecker < DataIntegrityChecker
  def slack_channel
    "#appeals-echo"
  end

  def call
    return if tasks_for_inactive_users.count == 0

    add_to_report "To resolve, see https://github.com/department-of-veterans-affairs/caseflow/wiki/Resolving-Background-Job-Alerts#tasksassignedtoinactiveusers"
    add_to_report "\nTask count grouped by task type: #{tasks_for_inactive_users.group(:type).count}"
    add_to_report "\nTask count grouped by assignee: #{task_count_by_assignee}"
    add_to_report "\ntype, appeal_type, appeal_id, task.id, assigned_to_id, status\n#{tasks_report}"
  end

  def tasks_for_inactive_users
    @tasks_for_inactive_users ||= Task.open.where(assigned_to: inactive_users)
  end

  private

  def tasks_report
    tasks_for_inactive_users.order(:type, :appeal_type, :appeal_id, :id, :assigned_to_id)
      .pluck(:type, :appeal_type, :appeal_id, :id, :assigned_to_id, :status)
      .map { |task_attribs| task_attribs.join(", ") }
      .join("\n")
  end

  def inactive_users
    User.where(status: :inactive)
  end

  def task_count_by_assignee
    tasks_for_inactive_users.group(:assigned_to_type, :assigned_to_id).count
  end
end
