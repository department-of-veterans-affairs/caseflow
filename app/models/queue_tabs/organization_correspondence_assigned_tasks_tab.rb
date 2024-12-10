# frozen_string_literal: true

class OrganizationCorrespondenceAssignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  # :reek:UtilityFunction
  def label
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_LABEL
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_TAB_NAME
  end

  # :reek:UtilityFunction
  def description
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_DESCRIPTION
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).assigned_tasks
  end

  # :reek:UtilityFunction
  def self.column_names
    columns = Constants.QUEUE_CONFIG.COLUMNS
    [
      columns.CHECKBOX_COLUMN.name,
      columns.VETERAN_DETAILS.name,
      columns.PACKAGE_DOCUMENT_TYPE.name,
      columns.VA_DATE_OF_RECEIPT.name,
      columns.DAYS_WAITING_CORRESPONDENCE.name,
      columns.TASK_TYPE.name,
      columns.TASK_ASSIGNEE.name,
      columns.NOTES.name
    ]
  end
end
