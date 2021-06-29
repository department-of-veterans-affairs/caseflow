# frozen_string_literal: true

##
# Checks for all open tasks assigned to inactive users.

class TasksAssignedToInactiveUsersChecker < DataIntegrityChecker
  def call
    return if inactive_tasks.count == 0

    add_to_report "type, appeal_type, appeal_id, task.id, assigned_to_id, status\n#{inactive_tasks_report}"
    add_to_report "Task count grouped by task type: #{inactive_tasks.group(:type).count}"
    add_to_report "Task count grouped by assignee: #{inactive_tasks.group(:assigned_to_id).count}"
    add_to_report "To resolve them, see https://github.com/department-of-veterans-affairs/caseflow/wiki/Resolving-Background-Job-Alerts#tasksassignedtoinactiveusers"
  end

  def inactive_tasks
    @inactive_tasks ||= Task.open.where(assigned_to: inactive_users)
  end

  private

  def inactive_tasks_report
    inactive_tasks.order(:type, :appeal_type, :appeal_id, :id, :assigned_to_id)
      .pluck(:type, :appeal_type, :appeal_id, :id, :assigned_to_id, :status)
      .map{|task_attribs| task_attribs.join(", ")}.join("\n")
  end

  def inactive_users
    User.where(status: :inactive)
  end
end
