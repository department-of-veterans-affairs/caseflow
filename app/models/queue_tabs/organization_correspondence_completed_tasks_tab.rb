# frozen_string_literal: true

class OrganizationCorrespondenceCompletedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_COMPLETED_TASKS_LABEL
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_COMPLETED_TASKS_TAB_NAME
  end

  def description
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_COMPLETED_TASKS_DESCRIPTION
  end

  def tasks
    completed_root_tasks = CorrespondenceRootTask.includes(:children).where(
      status: Constants.TASK_STATUSES.completed,
      assigned_to: assignee
    ).pluck(:id)

    tasks_with_completed_children = CorrespondenceRootTask.includes(:children).where.not(
      status: Constants.TASK_STATUSES.completed
    ).select do |task|
      task.children.all?(&:completed?)
    end.pluck(:id)

    CorrespondenceTask.includes(*task_includes)
      .where(id: completed_root_tasks + tasks_with_completed_children).recently_completed
  end

  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
  end
end
