# frozen_string_literal: true

class CorrespondenceAssignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_user

  # :reek:UtilityFunction
  def label
    Constants.QUEUE_CONFIG.CORRESPONDENCE_ASSIGNED_TASKS_LABEL
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CORRESPONDENCE_ASSIGNED_TASKS_TAB_NAME
  end

  # :reek:UtilityFunction
  def description
    Constants.QUEUE_CONFIG.CORRESPONDENCE_ASSIGNED_TASKS_DESCRIPTION
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).user_assigned_tasks(assignee)
  end

  # :reek:UtilityFunction
  def self.column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.PACKAGE_DOCUMENT_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
  end
end
