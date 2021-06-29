# frozen_string_literal: true

##
# Checks for all open tasks assigned to inactive users.

class TasksAssignedToInactiveUsersChecker < DataIntegrityChecker
  def call
    return if inactive_tasks.count == 0

    add_to_report "task ids: #{inactive_tasks.pluck(:id).join(",")}"
    add_to_report "See https://query.prod.appeals.va.gov/question/250 for a list of tasks"
    add_to_report "and https://github.com/department-of-veterans-affairs/caseflow/wiki/Resolving-Background-Job-Alerts#tasksassignedtoinactiveusers"
  end

  private

  def inactive_tasks
    @inactive_tasks ||= Task.open.where(assigned_to: inactive_users)
  end

  def inactive_users
    User.where(status: :inactive)
  end

end
