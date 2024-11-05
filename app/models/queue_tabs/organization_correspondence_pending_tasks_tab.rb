# frozen_string_literal: true

class OrganizationCorrespondencePendingTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  # :reek:UtilityFunction
  def label
    Constants.QUEUE_CONFIG.CORRESPONDENCE_PENDING_TASKS_LABEL
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CORRESPONDENCE_PENDING_TASKS_TAB_NAME
  end

  # :reek:UtilityFunction
  def description
    Constants.QUEUE_CONFIG.CORRESPONDENCE_PENDING_TASKS_DESCRIPTION
  end

  # :reek:UtilityFunction
  def tasks
    CorrespondenceTask.includes(*task_includes).pending_tasks
  end

  # :reek:UtilityFunction
  def self.column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.PACKAGE_DOCUMENT_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name
    ]
  end
end
