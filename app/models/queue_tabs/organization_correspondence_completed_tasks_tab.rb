# frozen_string_literal: true

class OrganizationCorrespondenceCompletedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  # :reek:UtilityFunction
  def label
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_COMPLETED_TASKS_LABEL
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_COMPLETED_TASKS_TAB_NAME
  end

  # :reek:UtilityFunction
  def description
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_COMPLETED_TASKS_DESCRIPTION
  end

  def tasks
    completed_root_task_ids = CorrespondenceRootTask.select(:id)
      .where(status: Constants.TASK_STATUSES.completed).pluck(:id)

    ids_with_completed_child_tasks = CorrespondenceTask.select(:parent_id)
      .where(status: Constants.TASK_STATUSES.completed)
      .where.not(type: CorrespondenceRootTask.name).distinct.pluck(:parent_id)

    ids_to_exclude = CorrespondenceTask.select(:parent_id)
      .where(parent_id: ids_with_completed_child_tasks)
      .open.distinct.pluck(:parent_id)

    CorrespondenceRootTask.includes(*task_includes)
      .where(id: completed_root_task_ids + ids_with_completed_child_tasks - ids_to_exclude)
  end

  # :reek:UtilityFunction
  def self.column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.PACKAGE_DOCUMENT_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.CORRESPONDENCE_TASK_CLOSED_DATE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
  end
end
