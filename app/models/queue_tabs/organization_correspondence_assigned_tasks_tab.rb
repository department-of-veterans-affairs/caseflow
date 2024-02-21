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
    CorrespondenceTask.includes(*task_includes).where(assigned_to: assignee).assigned
  end

  # :reek:UtilityFunction
  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.CHECKBOX_COLUMN.name,
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name
    ]
  end
end
